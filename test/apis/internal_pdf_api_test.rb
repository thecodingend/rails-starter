require "test_helper"
require "tempfile"

class InternalPdfApiTest < ActiveSupport::TestCase
  test "returns relevant excerpts from extracted PDF text" do
    pages = [
      { page: 1, text: "The onboarding checklist covers accounts and access." },
      { page: 2, text: "Refund policy requests must include the order number and customer email." },
      { page: 3, text: "Refund approvals are handled by the finance team." }
    ]

    with_temp_pdf do |path|
      with_stubbed_extract_pages(pages) do
        result = InternalPdfApi.search(query: "What is the refund policy?", path:)

        assert_equal path, result[:source]
        assert result[:matched]
        assert_equal 2, result.dig(:excerpts, 0, :page)
        assert_includes result.dig(:excerpts, 0, :text), "Refund policy"
      end
    end
  end

  test "returns first excerpts when there is no direct keyword match" do
    pages = [
      { page: 1, text: "Company handbook overview." },
      { page: 2, text: "Security responsibilities." }
    ]

    with_temp_pdf do |path|
      with_stubbed_extract_pages(pages) do
        result = InternalPdfApi.search(query: "summarize this document", path:)

        assert_not result[:matched]
        assert_equal 1, result.dig(:excerpts, 0, :page)
      end
    end
  end

  test "returns an error when the query is blank" do
    assert_equal({ error: "query is required" }, InternalPdfApi.search(query: " "))
  end

  test "returns an error before the internal PDF exists" do
    path = Rails.root.join("tmp/missing-internal-knowledge.pdf")
    FileUtils.rm_f(path)

    assert_equal(
      { error: "internal PDF not found", path: "tmp/missing-internal-knowledge.pdf" },
      InternalPdfApi.search(query: "refund policy", path:)
    )
  end

  private

  def with_temp_pdf
    file = Tempfile.new([ "internal-knowledge", ".pdf" ], Rails.root.join("tmp"))
    relative_path = Pathname.new(file.path).relative_path_from(Rails.root).to_s

    yield relative_path
  ensure
    file&.close
    file&.unlink
  end

  def with_stubbed_extract_pages(pages)
    original = InternalPdfApi.method(:extract_pages)
    InternalPdfApi.define_singleton_method(:extract_pages) { |_path| pages }

    yield
  ensure
    InternalPdfApi.define_singleton_method(:extract_pages) { |path| original.call(path) }
  end
end
