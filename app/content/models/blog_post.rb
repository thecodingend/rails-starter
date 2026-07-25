class BlogPost < Sitepress::Model
  def self.all = glob("blog/*.html*")
  def self.latest = all.sort_by(&:date).reverse

  data :title, :description

  def date = Date.parse(data.fetch("date").to_s)
end
