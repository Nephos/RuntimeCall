require "./spec_helper"

class Foo
  getter a : Int32
  getter b : String
  def initialize(@a, @b)
  end

  extend RuntimeCall
  getter_runtime_call("a", "b")
  define_runtime_call "bar", Int32 do |args|
    @a += args[0]
  end
  define_runtime_call "bar2", String do |args|
    @a += args[0] == "2" ? 2 : 0
  end

  include RuntimeCall::IReturnable
  define_runtime_call "self" do
    self
  end
end


describe RuntimeCall do
  it "test runtime calls" do
    foo = Foo.new 1, "2"
    foo.runtime_call("a", [] of String).should eq 1
    foo.runtime_call("b", [] of String).should eq "2"
    foo.runtime_call("bar", ["1"]).should eq 2
    foo.runtime_call("a", [] of String).should eq 2
    foo.runtime_call("bar2", ["2"]).should eq 4
    foo.runtime_call("a", [] of String).should eq 4
    foo.runtime_call("bar2", ["X"]).should eq 4
    foo.runtime_call("a", [] of String).should eq 4
    foo.runtime_call("self", [] of String).should eq foo
  end

  it "test runtime call errors" do
    foo = Foo.new 1, "2"
    expect_raises { foo.runtime_call("a", ["no_such_arg"]) }
    expect_raises { foo.runtime_call("b", ["a", "b"]) }
    expect_raises { foo.runtime_call("bar", ["1", "too_many"]) }
    expect_raises { foo.runtime_call("bar", [] of String) } # too few
  end

  it "test runtime calls with improved args" do
    foo = Foo.new 1, "2"
    foo.runtime_call("a").should eq 1
    foo.runtime_call("bar", 1).should eq 2
    foo.runtime_call("a").should eq 2
    expect_raises { foo.runtime_call("bar", 1, 1) }
  end
end
