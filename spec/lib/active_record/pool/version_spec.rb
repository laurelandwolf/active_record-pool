require "spec_helper"

RSpec.describe ActiveRecord::Pool::VERSION do
  it "is a string" do
    expect(ActiveRecord::Pool::VERSION).to be_kind_of(String)
  end
end
