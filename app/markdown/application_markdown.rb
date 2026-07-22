class ApplicationMarkdown < MarkdownRails::Renderer::Rails
  include Redcarpet::Render::SmartyPants

  def enable
    [ :fenced_code_blocks ]
  end
end
