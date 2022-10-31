# Chieftain

Chieftain is a library that provides an implementation of the Command design
pattern that attempts to make use of the capabilities of the Ruby language to
simplify usage. The library is heavily inspired by the
[Mutations](https://github.com/cypriss/mutations) but also seeks to address
a few pet peeves with that library.

Welcome to your new gem! In this directory, you'll find the files you need to
be able to package up your Ruby library into a gem. Put your Ruby code in the
file `lib/chieftain`. To experiment with that code, run `bin/console` for an
interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chieftain'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install chieftain

## Usage

The Command pattern encapsulates the functionality for a particular process
allowing it to be de-couple from where that functionality is invoked and to
allow the functionality to be test independently. With the Chieftain library
the pattern is implemented by creating a class that derives from the
``Chieftain::Command`` class. The example below shows and minimalistic
command class...

```ruby
  class ExampleCommand < Chieftain::Command
    def perform
      # Your command functionality goes here.
    end
  end
```

Here the ``ExampleCommand`` class derives from the ``Chieftain::Command`` class
and provides an implementation of the ``#perform()`` method. The ``#perform()``
method is where you place the code that performs the work on the command. An
example of using this class would look as follows...

```ruby
  command = ExampleCommand.new
  result  = command.execute
```

In this case the command takes no parameters bit but see the next section to see
how parameters are handled by the command. This example also shows how to invoke
the command functionality by calling the ``#execute()`` method. This method will
return a ``Chieftain::Command::Result`` instance that provides information on
the success or failure of the command execution.

Commands can fail for a number of reasons, including missing required
parameters, parameter values failing validation or conversion or because the
actual command perform code indicates a failure. You can check whether a
``Result`` instance represent a successful execution by invoking the
``#success?()`` method (or it's inverse ``#failed?()``).

If a command has failed then that means it will have one or more errors
generated during execution. You can access these directly by calling the
``#errors()`` method on the ``Result`` object. This returns an ``Array``
of ``Chieftain::Command::Error`` instances representing the errors for
the command execution. If you just want error message strings then call the
``#error_messages()`` method instead.

### Parameters

You can pass parameters to your command by passing a ``Hash`` containing the
parameters to the command constructor. The keys for this ``Hash`` should be
``Symbol``s, with the ``Symbol`` becoming the parameter name, so these will
also have to adhere to Ruby's method naming requirements.

Before you pass parameters to your command you should make the command class
aware that the parameter is expected. When 'declaring' your parameter to your
command class you should decide whether the parameter is mandatory or
optional. Required parameters, as might be expected, need to have a value
specified for them when the command is created. Optional parameters can
appear in a parameter list but isn't required to. So, an example of how
this may look is given below...

```ruby
  class CreatePerson < Chieftain::Command
    required :first_name
    required :last_name
    optional :middle_name
  end
```

Here the command has two parameters that must be provided when the command is
instantiated and one that may be provided. So the following are valid ways to
construct this command...

```ruby
  CreatePerson.new(first_name: "John", last_name: "Smith").execute
  CreatePerson.new(first_name: "Joseph",
                   middle_name: "Frank",
                   last_name: "Bloggs").execute
```

The required aspect of a parameter is not checked at construction but is instead
checked when you try to execute the command. If a required parameter is not
present in the commands parameter set then an error noting this will be
registered on the command, validation will fail, the ``#perform()`` method will
not be invoked and a fail result will be returned.

### Convertors

When defining parameters for a command you can also provide an indication of the
expected type for the parameter. An example of this is shown below...

```ruby
  class CreatePerson < Chieftain::Command
    required :name, type: :string
    optional :age, type: :integer
  end
```

In this case the command has two parameter defined. The first is expected to
be a string value and the second to be an integer. If the value actually
provided for the parameter is not of this type then an attempt will be made
to coerce to this type. If this effort fails then the command will fail
validation and return an unsuccessful result.

The Chieftain library defines the following types (and associated conversion
functionality) - :boolean, :float, :integer and :string. It is possible to
extend this set by defining a custom convertor class and making it available
to your command class.

Convertor classes are any class that provides an implementation for two methods
called ``#convertible?()`` and ``#convert()``. The ``#convertible()`` method
takes a single parameter which will be the raw value provided to the command for
the parameter. The method should determine whether this value can be converted
to the appropriate type, returning true if that is the case and false otherwise.
The ``#convert()`` method takes the same parameter but should return a value of
the appropriate type post conversion.

You can make a convertor class available as a type on a command class by
declaring it using the the ``#add_convertor()`` class method. The following
is an example of doing this...

```ruby
  # Convertor that converts a time string to the number of seconds since the
  # start of the day.
  class TimeConverter
    def convertible?(value)
      parts = value.to_s.split(":").map(&:to_i)
      parts.length == 3 &&
      (parts[0] >= 0 && parts[0] < 24) &&
      (parts[1] >= 0 && parts[1] < 60) &&
      (parts[2] >= 0 && parts[2] < 60)
    end

    def convert(value)
      parts = value.to_s.split(":").map(&:to_i)
      (parts[0] * 3600) + (parts[1] * 60) + parts[2]
    end
  end

  class ExampleCommand < Chieftain::Command
    required :timestamp, type: :time

    add_convertor :time, TimeConvertor
  end
```

Here a ``TimeConvertor`` class is first defined. The command then declares a
``:timestamp`` parameter and indicates it's ``type`` as ``:time``. After this
the command 'adds' a convertor by calling the ``#add_convertor()`` class. This
call takes two parameters. The first is the name to be associated with the new
convertor. The second is the convertor class.

One final note with regards to convertors. Custom convertors declared in a
parent class will be available in derived classes. Note that, if your derived
class adds a new convertor with a name that clashes with a convertor declared
in a parent, the new convertor takes precedence and the one from the parent
is not available.

### Validations

Validations are a mechanism for outlining a set of checks for a command
parameter. The library defines a set of predefined validations that are
available for use on every command. Additional validations can be defined
within a command and specified as applicable to a one or more of the command
parameters. An example of defining a validation is shown below...

```ruby
  class ExampleCommand < Chieftain::Command
    required :code, type: :string, validations: [:length_check]

    add_validator(:length_check) do |name, value|
      if value.length != 10
        error("The '#{name}' parameter must be exactly 10 characters in length.")
      end
    end
  end
```

In this example you can see that a single parameter with the name code is
defined for the ``ExampleCommand`` class. As part of the definition for this
parameter we see that the ``validations`` setting has been set to an ``Array``
containing the single ``Symbol`` ``:length_check``. This is the name of a
validations that is expected to exist and will be applied to the parameter
whenever validations take place.

Later in the class we can see the definition of the ``:length_check`` validation
using the ``#add_validator()`` method. This method takes a single parameter
which is the name of the validation. This must be a ``Symbol`` and validation
names must be unique within the context of a class.

The ``#add_validator()`` method also accepts a block, with the block defining
the functionality of the validation. This block will get executed within the
context of the invoking command class instance (i.e. ``self`` will refer to the
command instance). The block should also accept two parameters. The first is the
name of the parameter being validated. The second will be the value supplied for
the parameter.

In the example given above the validation checks that the parmaeter value
provided, which will be a string, must have a length of 10. In the case that the
value provided does not have this length then an error is register on the
command instance the validation was invoked by. There is another more concise
form that can be used to achieve the same result and this is shown in the
example below...

```ruby
  class ExampleCommand < Chieftain::Command
    required :code, type: :string

    validate(:code) do |name, value|
      if value.length != 10
        error("The '#{name}' parameter must be exactly 10 characters in length.")
      end
    end
  end
```

Here we define a validation using the ``#validate()`` method (which is really
just a synonym for the the ``#add_validator()`` method but is more fitting for
this form of the code). The validations has the same name as the parameter and
doing this will cause the command to automatically apply it to the parameter
when it gets validated.

One final note with regards to validations. Custom validations declared in a
parent class will be available in derived classes. Note that, if your derived
class adds a new validation with a name that clashes with a validation declared
in a parent, the new validation takes precedence and the one from the parent
is not available.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can
also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/chieftain.
