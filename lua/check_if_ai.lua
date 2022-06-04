local result = wesnoth.synchronize_choice(
                    function()
                        return { value = "no" }
                    end,
                    function()
                        -- Called only on the client
                        -- handling the current side,
                        -- if it is an AI.
                        return { value = "yes" }
                    end)
wesnoth.set_variable("steppe_is_ai"..wesnoth.current.side,result.value)