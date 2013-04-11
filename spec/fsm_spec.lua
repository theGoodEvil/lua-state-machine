require("busted")

local machine = require("statemachine")

describe("Lua state machine framework", function()
  describe("A stop light", function()
    local fsm
    local stoplight = {
      { name = 'warn',  from = 'green',  to = 'yellow' },
      { name = 'panic', from = 'yellow', to = 'red'    },
      { name = 'calm',  from = 'red',    to = 'yellow' },
      { name = 'clear', from = 'yellow', to = 'green'  }
    }

    before_each(function()
      fsm = machine.create({ initial = 'green', events = stoplight })
    end)

    it("should start as green", function()
      assert.are_equal(fsm.current, 'green')
    end)

    it("should not let you get to the wrong state", function()
      assert.is_false(fsm:panic())
      assert.is_false(fsm:calm())
      assert.is_false(fsm:clear())
    end)

    it("should let you go to yellow", function()
      assert.is_true(fsm:warn())
      assert.are_equal(fsm.current, 'yellow')
    end)

    it("should tell you what it can do", function()
      assert.is_true(fsm:can('warn'))
      assert.is_false(fsm:can('panic'))
      assert.is_false(fsm:can('calm'))
      assert.is_false(fsm:can('clear'))
    end)

    it("should tell you what it can't do", function()
      assert.is_false(fsm:cannot('warn'))
      assert.is_true(fsm:cannot('panic'))
      assert.is_true(fsm:cannot('calm'))
      assert.is_true(fsm:cannot('clear'))
    end)

    it("should support checking states", function()
      assert.is_true(fsm:is('green'))
      assert.is_false(fsm:is('red'))
      assert.is_false(fsm:is('yellow'))
    end)

    it("should fire handlers", function()
      fsm.will.leave.green = spy.new(function ()
        assert.are_equal(fsm.current, 'green')
      end)
      fsm.did.leave.green = spy.new(function ()
        assert.are_equal(fsm.current, 'yellow')
      end)
      fsm.will.apply.warn = spy.new(function ()
        assert.are_equal(fsm.current, 'green')
      end)
      fsm.did.apply.warn = spy.new(function ()
        assert.are_equal(fsm.current, 'yellow')
      end)
      fsm.will.enter.yellow = spy.new(function ()
        assert.are_equal(fsm.current, 'green')
      end)
      fsm.did.enter.yellow = spy.new(function ()
        assert.are_equal(fsm.current, 'yellow')
      end)

      fsm:warn()

      assert.spy(fsm.will.leave.green).was_called_with(fsm, 'warn', 'green', 'yellow')
      assert.spy(fsm.did.leave.green).was_called_with(fsm, 'warn', 'green', 'yellow')
      assert.spy(fsm.will.apply.warn).was_called_with(fsm, 'warn', 'green', 'yellow')
      assert.spy(fsm.did.apply.warn).was_called_with(fsm, 'warn', 'green', 'yellow')
      assert.spy(fsm.will.enter.yellow).was_called_with(fsm, 'warn', 'green', 'yellow')
      assert.spy(fsm.did.enter.yellow).was_called_with(fsm, 'warn', 'green', 'yellow')
    end)

    it("should accept additional arguments to handlers", function()
      fsm.will.leave.green = stub.new()
      fsm.did.leave.green = stub.new()
      fsm.will.apply.warn = stub.new()
      fsm.did.apply.warn = stub.new()
      fsm.will.enter.yellow = stub.new()
      fsm.did.enter.yellow = stub.new()

      fsm:warn('bar')

      assert.spy(fsm.will.leave.green).was_called_with(fsm, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.did.leave.green).was_called_with(fsm, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.will.apply.warn).was_called_with(fsm, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.did.apply.warn).was_called_with(fsm, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.will.enter.yellow).was_called_with(fsm, 'warn', 'green', 'yellow', 'bar')
      assert.spy(fsm.did.enter.yellow).was_called_with(fsm, 'warn', 'green', 'yellow', 'bar')
    end)

    it("should allow to customize the self argument for handlers", function()
      myself = { foo = 'bar' }
      fsm = machine.create({ initial = 'green', events = stoplight, self = myself })

      fsm.will.leave.green = stub.new()
      fsm.did.leave.green = stub.new()
      fsm.will.apply.warn = stub.new()
      fsm.did.apply.warn = stub.new()
      fsm.will.enter.yellow = stub.new()
      fsm.did.enter.yellow = stub.new()

      fsm:warn()

      assert.spy(fsm.will.leave.green).was_called_with(myself, 'warn', 'green', 'yellow')
      assert.spy(fsm.did.leave.green).was_called_with(myself, 'warn', 'green', 'yellow')
      assert.spy(fsm.will.apply.warn).was_called_with(myself, 'warn', 'green', 'yellow')
      assert.spy(fsm.did.apply.warn).was_called_with(myself, 'warn', 'green', 'yellow')
      assert.spy(fsm.will.enter.yellow).was_called_with(myself, 'warn', 'green', 'yellow')
      assert.spy(fsm.did.enter.yellow).was_called_with(myself, 'warn', 'green', 'yellow')
    end)

    it("should cancel the warn event from will.leave.green", function()
      fsm.will.leave.green = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("should cancel the warn event from will.apply.warn", function()
      fsm.will.apply.warn = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("should cancel the warn event from will.enter.yellow", function()
      fsm.will.enter.yellow = function(self, name, from, to) 
        return false
      end

      local result = fsm:warn()

      assert.is_false(result)
      assert.are_equal(fsm.current, 'green')
    end)

    it("can be extended with new events", function()
      fsm:add_event({ name = 'break_down', from = {'green', 'yellow', 'red'}, to = 'broken' })

      assert.is_true(fsm:break_down())
      assert.are_equal(fsm.current, 'broken')
    end)
  end)

  describe("A monster", function()
    local fsm
    local monster = {
      { name = 'eat',  from = 'hungry',                                to = 'satisfied' },
      { name = 'eat',  from = 'satisfied',                             to = 'full'      },
      { name = 'eat',  from = 'full',                                  to = 'sick'      },
      { name = 'rest', from = {'hungry', 'satisfied', 'full', 'sick'}, to = 'hungry'    }
    }

    before_each(function()
      fsm = machine.create({ initial = 'hungry', events = monster })
    end)

    it("can eat unless it is sick", function()
      assert.are_equal(fsm.current, 'hungry')
      assert.is_true(fsm:can('eat'))
      fsm:eat()
      assert.are_equal(fsm.current, 'satisfied')
      assert.is_true(fsm:can('eat'))
      fsm:eat()
      assert.are_equal(fsm.current, 'full')
      assert.is_true(fsm:can('eat'))
      fsm:eat()
      assert.are_equal(fsm.current, 'sick')
      assert.is_false(fsm:can('eat'))
    end)

    it("can always rest", function()
      assert.are_equal(fsm.current, 'hungry')
      assert.is_true(fsm:can('rest'))
      fsm:eat()
      assert.are_equal(fsm.current, 'satisfied')
      assert.is_true(fsm:can('rest'))
      fsm:eat()
      assert.are_equal(fsm.current, 'full')
      assert.is_true(fsm:can('rest'))
      fsm:eat()
      assert.are_equal(fsm.current, 'sick')
      assert.is_true(fsm:can('rest'))
      fsm:rest()
      assert.are_equal(fsm.current, 'hungry')
    end)
  end)
end)
