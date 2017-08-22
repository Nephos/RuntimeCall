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
end


describe RuntimeCall do
  it "test runtime calls" do
    foo = Foo.new 1, "2"
    foo.runtime_call("a", [] of String).should eq 1
    foo.runtime_call("b", [] of String).should eq "2"
    foo.runtime_call("bar", ["1"]).should eq 2
    foo.runtime_call("a", [] of String).should eq 2
  end

  it "test runtime call errors" do
    foo = Foo.new 1, "2"
    expect_raises { foo.runtime_call("a", ["no_such_arg"]) }
    expect_raises { foo.runtime_call("b", ["a", "b"]) }
    expect_raises { foo.runtime_call("bar", ["1", "too_many"]) }
    expect_raises { foo.runtime_call("bar", [] of String) } # too few
  end
end
