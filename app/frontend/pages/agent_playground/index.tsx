import { Form, Head, usePage } from '@inertiajs/react'

import { Button } from '@/components/ui/button'

type ToolCall = {
  id: number
  name: string
  arguments: Record<string, unknown>
}

type Message = {
  id: number
  role: string
  content: string | null
  tool_calls: ToolCall[]
}

type Chat = {
  id: number
  created_at: string
  messages: Message[]
}

type Props = {
  configured: boolean
  chats: Chat[]
}

export default function AgentPlayground({ configured, chats }: Props) {
  const { flash } = usePage()

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-5xl flex-col gap-8 px-6 py-8">
      <Head title="Agent Playground" />

      <header className="flex flex-col gap-2">
        <p className="text-sm font-medium text-muted-foreground">RubyLLM</p>
        <h1 className="text-3xl font-semibold tracking-normal">Agent Playground</h1>
        <p className="max-w-2xl text-sm text-muted-foreground">
          {configured ? 'LLM API access is configured.' : 'Set NVIDIA_API_KEY to run the agent.'}
        </p>
      </header>

      {(flash.notice || flash.alert) && (
        <div className="rounded-lg border border-border bg-muted px-4 py-3 text-sm">
          {flash.notice || flash.alert}
        </div>
      )}

      <Form method="post" action="/agent-playground" className="flex flex-col gap-3">
        {({ processing }) => (
          <>
            <textarea
              className="min-h-32 rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus:border-ring focus:ring-3 focus:ring-ring/50"
              name="prompt"
              placeholder="Ask what environment this app is running in."
            />
            <div>
              <Button type="submit" disabled={processing || !configured}>
                {processing ? 'Running...' : 'Run Agent'}
              </Button>
            </div>
          </>
        )}
      </Form>

      <section className="flex flex-col gap-4">
        <h2 className="text-lg font-medium">Recent Runs</h2>

        {chats.length === 0 ? (
          <p className="rounded-lg border border-dashed border-border px-4 py-6 text-sm text-muted-foreground">
            No agent runs yet.
          </p>
        ) : (
          chats.map((chat) => (
            <article className="rounded-lg border border-border" key={chat.id}>
              <div className="border-b border-border px-4 py-3 text-xs text-muted-foreground">
                Run #{chat.id} - {new Date(chat.created_at).toLocaleString()}
              </div>
              <div className="flex flex-col gap-3 p-4">
                {chat.messages.map((message) => (
                  <div className="flex flex-col gap-2 rounded-md bg-muted p-3" key={message.id}>
                    <div className="text-xs font-medium uppercase text-muted-foreground">
                      {message.role}
                    </div>
                    {message.content && (
                      <p className="whitespace-pre-wrap text-sm leading-6">{message.content}</p>
                    )}
                    {message.tool_calls.map((toolCall) => (
                      <pre
                        className="overflow-auto rounded-md bg-background p-3 text-xs"
                        key={toolCall.id}
                      >
                        {toolCall.name}: {JSON.stringify(toolCall.arguments, null, 2)}
                      </pre>
                    ))}
                  </div>
                ))}
              </div>
            </article>
          ))
        )}
      </section>
    </main>
  )
}
