require "pathname"
require "pdf/reader"

class InternalPdfApi
  PDF_PATH = Rails.root.join("storage/internal_knowledge.pdf")
  EXCERPT_LIMIT = 3
  CHUNK_SIZE = 1_200
  MIN_TERM_LENGTH = 3

  def self.search(query:, path: PDF_PATH)
    query = query.to_s.strip
    return { error: "query is required" } if query.empty?

    pdf_path = normalize_path(path)
    return { error: "internal PDF not found", path: relative_path(pdf_path) } unless pdf_path.exist?

    chunks = build_chunks(extract_pages(pdf_path))
    return { error: "internal PDF has no extractable text", path: relative_path(pdf_path) } if chunks.empty?

    terms = query_terms(query)
    scored_chunks = chunks.map { |chunk| chunk.merge(score: score(chunk[:text], terms)) }
    matching_chunks = scored_chunks.select { |chunk| chunk[:score].positive? }
    selected_chunks = select_chunks(scored_chunks, matching_chunks)

    {
      source: relative_path(pdf_path),
      query:,
      matched: matching_chunks.any?,
      excerpts: selected_chunks.map { |chunk| { page: chunk[:page], text: chunk[:text] } }
    }
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError, ArgumentError, IOError => error
    { error: "internal PDF could not be read", detail: error.class.name }
  end

  def self.extract_pages(path)
    PDF::Reader.new(path.to_s).pages.each_with_index.map do |page, index|
      { page: index + 1, text: normalize_text(page.text) }
    end
  end

  def self.build_chunks(pages)
    pages.flat_map do |page|
      text = page[:text].to_s
      next [] if text.empty?

      chunk_text(text).map { |chunk| { page: page[:page], text: chunk } }
    end
  end

  def self.chunk_text(text)
    chunks = []
    offset = 0

    while offset < text.length
      chunks << text[offset, CHUNK_SIZE].strip
      offset += CHUNK_SIZE
    end

    chunks.reject(&:empty?)
  end

  def self.select_chunks(scored_chunks, matching_chunks)
    chunks = if matching_chunks.any?
      matching_chunks.sort_by { |chunk| [ -chunk[:score], chunk[:page] ] }
    else
      scored_chunks
    end

    chunks.first(EXCERPT_LIMIT)
  end

  def self.score(text, terms)
    return 0 if terms.empty?

    downcased_text = text.downcase
    terms.sum { |term| downcased_text.scan(/\b#{Regexp.escape(term)}\b/).size }
  end

  def self.query_terms(query)
    query.downcase.scan(/[[:alnum:]]+/).reject { |term| term.length < MIN_TERM_LENGTH }.uniq
  end

  def self.normalize_text(text)
    text.to_s.gsub(/\s+/, " ").strip
  end

  def self.normalize_path(path)
    pathname = Pathname.new(path.to_s)
    pathname.absolute? ? pathname : Rails.root.join(pathname)
  end

  def self.relative_path(path)
    path.relative_path_from(Rails.root).to_s
  rescue ArgumentError
    path.to_s
  end
end
