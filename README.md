# RuntimeCall

Runtime calls in crystal

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  RuntimeCall:
    github: Nephos/RuntimeCall
```

## Usage

```crystal
require "RuntimeCall"

class Foo
  getter a : Int32
  def initialize(@a)
  end

  extend RuntimeCall
  getter_runtime_call("a")
  define_runtime_call "bar", Int32 do |args|
    @a += args[0]
  end
end

foo = Foo.new a: 1
foo.runtime_call "bar", 2
foo.runtime_call "a" # => 3
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/Nephos/RuntimeCall/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Nephos](https://github.com/Nephos) Arthur Poulet - creator, maintainer
