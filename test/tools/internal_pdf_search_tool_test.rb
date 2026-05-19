require "test_helper"

class InternalPdfSearchToolTest < ActiveSupport::TestCase
  test "returns PDF search results from the internal PDF api" do
    expected = {
      source: "storage/internal_knowledge.pdf",
      query: "refund policy",
      matched: true,
      excerpts: [ { page: 2, text: "Refund policy requests must include the order number." } ]
    }

    original = InternalPdfApi.method(:search)
    InternalPdfApi.define_singleton_method(:search) { |query:| expected.merge(query:) }

    assert_equal expected, InternalPdfSearchTool.new.execute(query: "refund policy")
  ensure
    InternalPdfApi.define_singleton_method(:search) { |**kwargs| original.call(**kwargs) }
  end
end
