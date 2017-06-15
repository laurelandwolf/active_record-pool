# active_record-pool

  - ![Build](http://img.shields.io/travis-ci/laurelandwolf/active_record-pool.svg?style=flat-square)
  - ![Downloads](http://img.shields.io/gem/dtv/active_record-pool.svg?style=flat-square)
  - ![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)
  - ![Version](http://img.shields.io/gem/v/active_record-pool.svg?style=flat-square)


active_record-pool is an extension to active_record that gives you an interface to write high-speed inserts, updates, & delete in a manageable way.

Normally developers will write migrations (as in `bin/rake db:migrate`) using the ActiveRecord::Migration tools for changing their data. I believe this to be an anti-pattern. Every system I've worked at that has done this style has resulted in completely breaking their ability to rebuild from scratch due to the domain models or file systems changing.


## Using

``` ruby
require 'active_record/write'

class Person < ActiveRecord::Base
  # column :name, Text, index: true
  # column :email, Text, index: { unique: true }
  # column :encrypted_password, Text
end
```

``` sql
CREATE TABLE persons (
    id uuid NOT NULL,
    first_name text,
    last_name text,
    name text,
    email text,
    encryped_passwrd text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE UNIQUE INDEX index_persons_on_email ON persons USING btree (email);
CREATE INDEX index_persons_on_first_name ON persons USING btree (first_name);
CREATE INDEX index_persons_on_last_name ON persons USING btree (last_name);
CREATE INDEX index_persons_on_name ON persons USING btree (name);
CREATE INDEX index_persons_on_created_at ON persons USING btree (created_at);
CREATE INDEX index_persons_on_updated_at ON persons USING btree (updated_at);
```

Normally I would see developers write:

``` ruby
class CombineFirstNameAndLastNameOnPersons < ActiveRecord::Migration
   def change
     Person.find_each do |person|
       person.name = person.first_name + " " + person.last_name
       person.save
     end
   end
  end
end
```

However it's painful for two reasons:

  - `Person` might not always be the model class
  - `Person` might not always have `first_name`, `last_name`
  - You probably don't actually want to run callbacks
  - So much. G
  - arba
  - ge collec
  - tion.

Here's the alternative

``` ruby
class CombineFirstNameAndLastNameOnPersons < ActiveRecord::Migration
   def change
     return unless defined? Person
     Person.pool(columns: [:id, :first_name, :last_name]) do |id, first, last|
       update(id, name: "#{first} #{last}")
     end
   end
  end
end
```

Every `pool()` function needs to end in either a single `insert()`, `update()`, or `Arel::*Manager` or an array of those:

``` ruby
Cart.pool(columns: [:items_as_json], target: 'items') do |items|
  items.map do |item|
    insert(item)
  end
end
```

As above, to specify a different table from the `ActiveRecord::Base` subject provide the `target: "..."` argument.

Each of these blocks gets executed, inside a transaction, concurrently for each available connection pool it can freely access up to size:

``` ruby
Cart.pool(columns: [:items_as_json], size: 100)
```

In order to have a more focused query use the `query: ...` keyword:

``` ruby
Cart.pool(query: Cart.where(%|"carts"."items" ->> IS NOT NULL|), columns: [:items_as_json])
```

By default write will assume complex data structures (`Array` or `Hash`) should be serialized via `JSON`, instead you can:

``` ruby
Cart.pool(columns: [:id], serialize: YAML)
```


## Installing

Add this line to your application's Gemfile:

    gem "active_record-pool", "~> 1.0"

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install active_record-write


## Contributing

  1. Read the [Code of Conduct](/CONDUCT.md)
  2. Fork it
  3. Create your feature branch (`git checkout -b my-new-feature`)
  4. Commit your changes (`git commit -am 'Add some feature'`)
  5. Push to the branch (`git push origin my-new-feature`)
  6. Create new Pull Request


## License

Copyright (c) 2017 Laurel & Wolf

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
