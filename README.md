# pico-nn

A pico-8 based neural network with genetic algorithms.

[itch.io page](https://fartenko.itch.io/pico-nn)

[Lexaloffle BBS post]()

## Getting started

Just copy code from here and use it in pico-8 or other lua app.

You also can download pico-8 carts on [Lexaloffle BBS]() or [Itch]().

Also note that nn's draw function won't work in other lua applications, because its using pico-8's built-in functions.

## Usage

A simple example on how to use it:

   	function _init()
	    layers = {3, 5, 3}
	    net = nn:new(layers)
	    net:init_neurons()
	    net:init_weights()
	end

	function _update()
		local input = {0.2, 0.5, 0.4}
		local output = net:feed_forward(input)
		local class = get_class(output)

		if class == 1 then
			-- do some action
		elseif class == 2 then
			-- do some other action
		else 
			-- do a completely different action
		end

		net:addfit(1 / 60)

		-- network mutation
		if condition then
			net:mutate()
		end
	end

	function _draw()
		local x, y = 4, 4
		local w, h = 120, 64
		net:draw(x, y, w, h)
	end

## Todo

* Figure out a way to save trained model
* ...and a way to load it
