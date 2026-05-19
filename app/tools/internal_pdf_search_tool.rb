class InternalPdfSearchTool < RubyLLM::Tool
  desc "Searches the internal PDF knowledge file for excerpts relevant to a question."
  param :query, type: :string, desc: "The user's question to answer from the internal PDF."

  def execute(query:)
    InternalPdfApi.search(query:)
  end
end
