class String
  # custom `case` method
  def leetcase
    out = self.upcase
    "AEIOUY".freeze.each_char do |c|
      out.gsub!(c, c.downcase)
    end
    out
  end
end

class Person < ActiveRecord::Base
  sanitizes case: :title, except: :description
  sanitizes only: [:first_name, :last_name], case: :up
  sanitizes only: :email, case: :downcase
  sanitizes only: :description, include_text_type: true
  sanitizes only: :do_not_collapse, collapse: false

  # `sanitization` is an alias of `sanitizes`
  sanitization only: '1337', case: :leet
end

RSpec.describe Sanitization do
  let(:values) {
    { first_name: " john ",
      last_name: " smith ",
      title: " chief executive officer ",
      email: "  JOHN@EXAMPLE.ORG  ",
      description: "  John is    CEO of ACME INC.  He has been with the company for 12 years.  ",
      education: " harvard  business  school    ",
      dob: Date.new(1950,1,1),
      age: 72,
      city: "  ",
      address: "  ",
      do_not_collapse: "   DO  NOT  COLLAPSE  ME   ",
      '1337': " 1337 HAX0R WAREZ BBS SYS0P  " }
  }

  it "has a version number" do
    expect(Sanitization::VERSION).not_to be nil
  end

  context "With defaults and some configuration set" do
    before(:all) do
      Sanitization.simple_defaults!
    end

    let!(:person1) { Person.create(values) }

    it "works as it should" do
      expect(person1.first_name).to eq("JOHN") # strip, upcase
      expect(person1.last_name).to eq("SMITH") # strip, upcase
      expect(person1.title).to eq("Chief Executive Officer")  # strip, titlecase
      expect(person1.description).to eq("John is CEO of ACME INC. He has been with the company for 12 years.")  # strip and collapse
      expect(person1.education).to eq(" harvard  business  school    ")  # not formatted because text columns are not formatted by default
      expect(person1.email).to eq("john@example.org")  # downcase and strip
      expect(person1.dob).to eq(Date.new(1950,1,1))
      expect(person1.age).to eq(72)
      expect(person1.address).to be_nil # empty and nullable
      expect(person1.city).to eq("")    # empty and not nullable
      expect(person1.do_not_collapse).to eq("Do  Not  Collapse  Me")  # strip, titlecase, but do not collapse spaces
      expect(person1['1337']).to eq("1337 HaX0R WaReZ BBS SyS0P")
    end
  end

  context "With clear default configuration" do
    before(:all) do
      Sanitization.configuration.clear!
    end

    let!(:person1) { Person.create(values) }

    it "works as it should" do
      expect(person1.first_name).to eq(" JOHN ") # upcase
      expect(person1.last_name).to eq(" SMITH ") # upcase
      expect(person1.title).to eq(" Chief Executive Officer ")  # titlecase
      expect(person1.description).to eq(values[:description]) # left as is
      expect(person1.education).to eq(" harvard  business  school    ")  # not formatted because text columns are not formatted by default
      expect(person1.email).to eq("  john@example.org  ")  # downcase
      expect(person1.dob).to eq(Date.new(1950,1,1))
      expect(person1.age).to eq(72)
      expect(person1.address).to eq(values[:address]) # left as is
      expect(person1.city).to eq(values[:city]) # left as is
      expect(person1.do_not_collapse).to eq("   Do  Not  Collapse  Me   ")  # titlecase
      expect(person1['1337']).to eq(" 1337 HaX0R WaReZ BBS SyS0P  ")
    end
  end
end
