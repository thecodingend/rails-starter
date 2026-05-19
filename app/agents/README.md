# Agentic Setup

This app uses RubyLLM to run a Rails-backed assistant with persisted chats, messages,
tool calls, and model metadata.

The main entry point is `AppAssistant`:

```rb
chat = AppAssistant.create!
chat.ask("How many widgets do we have?")
```

In the browser, use:

```text
/agent-playground
```

## Local Setup

Start Postgres first:

```sh
docker compose up -d db
mise exec -- bin/rails db:prepare
```

Add local LLM credentials in `rails-starter/.env`:

```env
NVIDIA_API_KEY=nvapi-***
NVIDIA_MODEL=mistralai/mistral-medium-3.5-128b
NVIDIA_API_BASE=https://integrate.api.nvidia.com/v1
```

The `.env` file is ignored by git. Do not commit API keys.

NVIDIA works here because the app configures RubyLLM through its OpenAI-compatible
provider settings:

```rb
config.openai_api_key = ENV["NVIDIA_API_KEY"]
config.openai_api_base = ENV.fetch("NVIDIA_API_BASE", "https://integrate.api.nvidia.com/v1")
```

Run the app:

```sh
mise exec -- bin/dev
```

`bin/dev` starts Vite and Rails. Rails listens on `127.0.0.1:3100` by default and
redirects to `localhost:3100`.

To stop the app, press `Ctrl-C` in the terminal running `bin/dev`.

## Files To Know

```text
app/agents/app_assistant.rb
app/tools/*.rb
app/apis/*.rb
app/models/llm_chat.rb
app/models/llm_message.rb
app/models/llm_tool_call.rb
app/models/llm_model.rb
app/controllers/agent_playground_controller.rb
app/frontend/pages/agent_playground/index.tsx
config/initializers/ruby_llm.rb
db/migrate/*llm*
```

## How Persistence Works

RubyLLM does not store conversations by itself unless you give it ActiveRecord
models. The app has four LLM persistence models:

```rb
class LlmChat < ApplicationRecord
  acts_as_chat messages: :llm_messages, model: :llm_model
end

class LlmMessage < ApplicationRecord
  acts_as_message chat: :llm_chat, tool_calls: :llm_tool_calls, model: :llm_model
end

class LlmToolCall < ApplicationRecord
  acts_as_tool_call message: :llm_message
end

class LlmModel < ApplicationRecord
  acts_as_model chats: :llm_chats
end
```

The migrations create the tables and columns. The `acts_as_*` macros do not create
tables. They tell RubyLLM how to use those tables:

- `acts_as_chat` adds chat behavior like `ask`, `with_tools`, `with_model`,
  message persistence, and conversion to a RubyLLM chat.
- `acts_as_message` makes a row behave like a RubyLLM message, including role,
  content, token data, tool call links, and cost helpers.
- `acts_as_tool_call` stores tool call metadata such as tool name, call id, and
  JSON arguments.
- `acts_as_model` stores model registry data such as provider, model id,
  capabilities, pricing, and context window.

Typical run flow:

```text
AppAssistant.create!
  -> creates an LlmChat

chat.ask(prompt)
  -> creates LlmMessage(role: user)
  -> sends chat history to the LLM
  -> model may request a tool
  -> creates LlmToolCall(name, arguments)
  -> executes the Ruby tool
  -> creates LlmMessage(role: tool)
  -> creates LlmMessage(role: assistant)
```

## AppAssistant

`AppAssistant` is the configured assistant for this app:

```rb
class AppAssistant < RubyLLM::Agent
  chat_model LlmChat
  model ENV.fetch("NVIDIA_MODEL", "mistralai/mistral-medium-3.5-128b"),
    provider: :openai,
    assume_model_exists: true
  temperature 0.0
  tools AppStatusTool, InventoryCountTool, CurrentWeatherTool, InternalPdfSearchTool
end
```

Important settings:

- `chat_model LlmChat` means conversations persist through the `llm_chats` tables.
- `provider: :openai` is used because NVIDIA exposes an OpenAI-compatible API.
- `assume_model_exists: true` avoids registry validation issues for NVIDIA-hosted
  model ids that may not exist in RubyLLM's built-in model registry.
- `tool_choice: "auto"` lets the model decide when to call tools.
- `temperature 0.0` keeps answers more deterministic.

The instructions in `AppAssistant` are important. They tell the model when to use
each tool. If you add a new tool, update both the `tools` list and the instructions.

## Current Tools

### `app_status`

File: `app/tools/app_status_tool.rb`

Returns basic runtime information:

```rb
{
  environment: Rails.env,
  rails_version: Rails.version,
  ruby_version: RUBY_VERSION,
  current_time: Time.current.iso8601
}
```

Use when users ask about app status, versions, environment, or current time.

### `inventory_count`

File: `app/tools/inventory_count_tool.rb`

Calls `InventoryApi.count_items(name:)` and returns local inventory data from the
database.

Use when users ask how many units of an item are available.

### `current_weather`

File: `app/tools/current_weather_tool.rb`

Calls `OpenMeteoApi.current_weather(location:)`. This uses Open-Meteo's public
geocoding and forecast APIs, with no API key.

Use when users ask about current weather for a location.

### `internal_pdf_search`

File: `app/tools/internal_pdf_search_tool.rb`

Calls `InternalPdfApi.search(query:)`. It reads:

```text
storage/internal_knowledge.pdf
```

It extracts PDF text, splits it into chunks, scores chunks by query terms, and
returns the best excerpts. The LLM should answer from those excerpts.

If the file does not exist yet, the tool returns:

```rb
{ error: "internal PDF not found", path: "storage/internal_knowledge.pdf" }
```

## Tool Pattern

Keep tools thin. Put external IO, database lookups, parsing, and formatting in an
API-style class under `app/apis`. The tool should mostly define the LLM-facing
schema and delegate.

Example:

```rb
class SomeTool < RubyLLM::Tool
  desc "Does one specific thing."
  param :name, type: :string, desc: "The name to look up."

  def execute(name:)
    SomeApi.lookup(name:)
  end
end
```

Then register it:

```rb
tools AppStatusTool, InventoryCountTool, CurrentWeatherTool, InternalPdfSearchTool, SomeTool
```

And update the assistant instructions:

```rb
"Use the some_tool tool when ..."
```

## Adding A New Tool

Use this checklist:

1. Add an API wrapper under `app/apis`.
2. Add a RubyLLM tool under `app/tools`.
3. Register the tool in `AppAssistant`.
4. Add one instruction sentence telling the model when to use it.
5. Add focused tests for the API wrapper.
6. Add one tool test proving the tool delegates correctly.
7. Run focused tests, then the full suite.

Example commands:

```sh
mise exec -- bin/rails test test/apis/some_api_test.rb test/tools/some_tool_test.rb
mise exec -- bin/rails test
```

## Testing Guidance

Tools should not make real network calls in tests. Stub the API wrapper boundary
or the low-level request method.

For example, `CurrentWeatherToolTest` stubs `OpenMeteoApi.current_weather`, and
`OpenMeteoApiTest` stubs `request_json`.

Keep tests focused on behavior:

- Required input errors.
- Not-found or unavailable cases.
- Successful return shape.
- Tool delegation to the API wrapper.

## Common Local Issues

### Database connection error

If Rails shows:

```text
ActiveRecord::DatabaseConnectionError
There is an issue connecting with your hostname: 127.0.0.1
```

Start the DB and prepare it:

```sh
docker compose up -d db
mise exec -- bin/rails db:prepare
```

### Missing API key

If the playground says API access is not configured, check:

```sh
cat .env
```

Then restart `bin/dev`. Environment variables are read when the process starts.

### Server already running

Stop the terminal running `bin/dev` with `Ctrl-C`.

If a process is stuck on the port:

```sh
lsof -i :3100
kill <PID>
```

### Internal PDF not found

Put the file here:

```text
storage/internal_knowledge.pdf
```

Then ask a question that clearly references the internal PDF.

## Verification Commands

Run these before handing off agent changes:

```sh
mise exec -- bin/rails zeitwerk:check
mise exec -- bin/rubocop app/agents app/tools app/apis test/tools test/apis
mise exec -- bin/rails test
```

