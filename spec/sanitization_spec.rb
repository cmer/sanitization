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
      expect(person1.description).to eq(values[:description]) # left as is
      expect(person1.education).to eq(" harvard  business  school    ")  # not formatted because text columns are not formatted by default
      expect(person1.email).to eq("  john@example.org  ")  # downcase
      expect(person1.dob).to eq(Date.new(1950,1,1))
      expect(person1.age).to eq(72)
      expect(person1['1337']).to eq(" 1337 HaX0R WaReZ BBS SyS0P  ")

      # ActiveSupport 7's titlecase method strips leading spaces
      if ActiveSupport::VERSION::MAJOR < 7
        expect(person1.title).to eq(" Chief Executive Officer ")
        expect(person1.address).to eq(values[:address])
        expect(person1.city).to eq(values[:city]) # left as is
        expect(person1.do_not_collapse).to eq("   Do  Not  Collapse  Me   ")  # titlecase
      else
        expect(person1.title).to eq("Chief Executive Officer ")
        expect(person1.address).to eq("")
        expect(person1.city).to eq("") # left as is
        expect(person1.do_not_collapse).to eq("Do  Not  Collapse  Me   ")  # titlecase
      end
    end
  end

  context "Assignment-time semantics (normalizes integration)" do
    before(:all) { Sanitization.simple_defaults! }

    let(:base_attrs) {
      { first_name: "John", last_name: "Smith", city: "NYC",
        email: "user@example.org", do_not_collapse: "x" }
    }

    it "normalizes on assignment, before save" do
      person = Person.new
      person.first_name = " john "
      expect(person.first_name).to eq("JOHN")
      expect(person.persisted?).to be false
    end

    it "normalizes attributes passed to .new" do
      person = Person.new(first_name: "  jane  ", email: "  USER@X.ORG  ")
      expect(person.first_name).to eq("JANE")
      expect(person.email).to eq("user@x.org")
    end

    it "leaves nil values as nil (apply_to_nil: false default)" do
      person = Person.new(first_name: nil)
      expect(person.first_name).to be_nil
    end

    it "is idempotent — normalizing a normalized value is a no-op" do
      once  = Person.normalize_value_for(:email, "  USER@X.ORG  ")
      twice = Person.normalize_value_for(:email, once)
      expect(once).to eq("user@x.org")
      expect(twice).to eq(once)
    end

    it "normalizes hash conditions in .where" do
      Person.create!(base_attrs.merge(email: "raw@example.org"))
      expect(Person.where(email: "  RAW@EXAMPLE.ORG  ").count).to be >= 1
    end

    it "normalizes the lookup value in .find_by" do
      Person.create!(base_attrs.merge(email: "lookup@example.org"))
      expect(Person.find_by(email: "  LOOKUP@EXAMPLE.ORG  ")).not_to be_nil
    end

    it "does NOT auto-normalize legacy rows on plain save" do
      person = Person.create!(base_attrs.merge(email: "legacy@example.org"))
      ActiveRecord::Base.connection.execute(
        "UPDATE people SET email = '  LEGACY-RAW@X.ORG  ' WHERE id = #{person.id}"
      )
      person.reload
      expect(person.email).to eq("  LEGACY-RAW@X.ORG  ") # reload does not normalize
      person.last_name = "OTHER"
      person.save!
      person.reload
      expect(person.email).to eq("  LEGACY-RAW@X.ORG  ") # unrelated save did not heal it
    end

    it "migrates legacy rows on demand via normalize_attribute" do
      person = Person.create!(base_attrs.merge(email: "migrate@example.org"))
      ActiveRecord::Base.connection.execute(
        "UPDATE people SET email = '  MIGRATE-RAW@X.ORG  ' WHERE id = #{person.id}"
      )
      person.reload
      person.normalize_attribute(:email)
      person.save!
      person.reload
      expect(person.email).to eq("migrate-raw@x.org")
    end

    it "re-normalizes values mutated in place before validation" do
      person = Person.new(base_attrs)
      person.email << "   "  # mutate in place
      person.valid?          # before_validation hook re-normalizes
      expect(person.email).to eq("user@example.org")
    end

    it "runs validations against normalized values" do
      validating = Class.new(Person) do
        def self.name; "ValidatingPerson"; end
        validates_each :email do |record, attr, value|
          record.errors.add(attr, "must be lowercase") if value && value != value.downcase
        end
      end
      person = validating.new(base_attrs.merge(email: "  RAW@X.ORG  "))
      expect(person.email).to eq("raw@x.org")
      expect(person.valid?).to be true
    end
  end
end
