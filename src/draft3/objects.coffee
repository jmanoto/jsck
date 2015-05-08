module.exports =

  properties: (definition, context) ->
    self = @
    if !self.test_type "object", definition
      throw new Error "The 'properties' attribute must be an object"
    tests = {}
    required = []
    for property, schema of definition
      new_context = context.child(property)
      test = self.compile(new_context, schema)
      tests[property] = test
      if schema.required == true
        required.push property

    (data, runtime) ->
      if self.test_type "object", data
        for property, value of data
          if (test = tests[property])?
            test value, runtime.child(property)
        for key in required
          if data[key] == undefined
            runtime.error context.child(key).child("required")
        true


  dependencies: (definition, context) ->
    self = @
    unless self.test_type "object", definition
      throw new Error "Value of 'dependencies' must be an object"
    else
      tests = []
      for property, dependency of definition

        if self.test_type "string", dependency
          tests.push (data, runtime) ->
            if data[property]? && !data[dependency]?
              runtime.child(property).error context

        else if self.test_type "array", dependency
          tests.push (data, runtime) ->
            if data[property]?
              for item in dependency
                if !data[item]?
                  runtime.child(property).error context
              null

        else if self.test_type "object", dependency
          fn = self.compile context, dependency
          tests.push (data, runtime) ->
            if data[property]
              fn data, runtime
            else
              true

        else
          throw new Error "Invalid dependency"

    (data, runtime) ->
      if self.test_type "object", data
        for test in tests
          test data, runtime
        null
