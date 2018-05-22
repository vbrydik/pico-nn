function _init()
    -- creating layers
    layers={5,5,2}
    
    -- craeting a network
    net=nn:new(layers)
    net:init_neurons()
    net:init_weights()
    
    -- max fit network
    max_fit_net=nil
    max_fit=0
    generation=1
    
    -- palette used by network
    heat_pal={1,2,8,14,7}
    
    -- ball object
    b=ball:new(32,32)
    
    -- target
    tx=96
    ty=96
    
    dist=0
    timer=200
    
    t=0
end


function _update60()
    -- creating some inputs and getting outputs
    -- recomended range is 0..1
    local input={
     dist/180,
     b.x/128,
     b.y/128,
     tx/128,
     ty/128
     }
    local output=net:feed_forward(input)
    
    -- getting index/class of the output
    local class=get_class(output)
    
    -- doing some action on a ball
    if class==1 then
        b:add_ang(-0.01)
    else 
        b:add_ang(0.01)
    end
    
    -- ball update
    b:update()

    -- calculating distance between ball and a target   
    dist=sqrt((b.x-tx)^2+(b.y-ty)^2)
    
    -- setting fit
    net:setfit(180-dist)

    t+=1
    timer-=1
    
    -- checking if we can preceed to a new generation
    -- if we do, we will create a new network   
    if (timer<=0 and dist>16)
        or (b.x<5 or b.x>122 
        or  b.y<5 or b.y>122)
    then
        -- we proceed to a new generation
        generation+=1
    
        -- reset a timer and a ball
        timer=200
        b=ball:new(32,32)
        
        -- getting saving a max fitted network
        if net:getfit()>max_fit then
            max_fit=net:getfit()
            max_fit_net=nn:make_copy_of(net)
        end
        
        -- replacing our network with a max fitted one
        if max_fit_net!=nil then            
            net=nn:make_copy_of(max_fit_net)
        end
    
        -- and mutate it
        net:mutate()
    end
end


function _draw()
    cls()
    rect(1,1,126,126,1)
    
    -- network
    fillp(0b01011010010110100101)
    net:draw(4,88,48,32)
    fillp()
    
    -- drawing a target
    circ(tx,ty,16,3)
    circ(tx,ty,3,11)
    pset(tx,ty,11)
    
    -- drawjng a ball
    b:draw()
    
    -- debug
    print("curfit:"..net:getfit(),1,1,7)
    print("maxfit:"..max_fit,1,7,7)
    print("generation:"..generation,1,13,7)
end

------------------------------------------------------------

-- +-------+
-- | tools |
-- +-------+

-- hiberbolic tangent function
function tanh(x)
    return sinh(x)/cosh(x)
end
-- hiperbolic cos
function cosh(x)
    return 0.5*(exp(x)-exp(-x))
end
-- hiperbolic sin
function sinh(x)
    return 0.5*(exp(x)+exp(-x)) 
end
-- exp
function exp(x)
    local e=2.71828183
    return e^x
end
-- returns index of a cell with max value
function get_class(out)
    local idx=1
    for i=2,#out do
        local o=out[i]
        if o>out[idx] then idx=i end
    end 
    return idx
end

-----------------------------------------------------------------------

-- +----------------+
-- | neural network |
-- +----------------+

nn={} -- nn short for neural networlk

-- creating a new neural network
function nn:new(layers)
    local this={}

    this.layers={} --layers
    this.neurons={}--neurons
    this.weights={}--weights
    this.fitness=0
    
    -- creating layers
    for i=1,#layers do
        this.layers[i]=layers[i]
    end

    self.__index=self
    setmetatable(this,self)
    
    return this
end

-- makes a copy of another network
function nn:make_copy_of(net)
    local this={}
    
    this.layers=net.layers
    this.neurons=net.neurons
    this.weights=net.weights
    this.fitness=0

    self.__index=self
    setmetatable(this,self)
    
    return this
end

-- neurons initialization
function nn:init_neurons()
    -- for each layer
    for i=1,#self.layers do
        local _n={}
        -- for num of neurons in layers
        for j=1,self.layers[i] do
            -- create neuron/bias
            _n[j]=0
        end
        -- adding neuron to neurons table
        add(self.neurons,_n)
    end
end

-- creating weights (connections between neurons)
function nn:init_weights()
    -- for each layer (with offset)
    for i=2,#self.layers do
        
        -- layers table and num of neurons in previous layer
        local l_weights={}
        local n_prev_l=self.layers[i-1]
        
        -- for each neuron in layer
        for j=1,#self.neurons[i] do
            -- create weights table
            local n_weights={}
            -- for each neuron in prev layer
            for k=1,n_prev_l do
                -- create random weights
                n_weights[k]=rnd(1)-0.5
            end
            -- adding weights to layers table
            add(l_weights,n_weights)
        end
        -- adding layer weights table to weights table
        add(self.weights,l_weights)
    end
end

-- feed forward inputs to get output
function nn:feed_forward(inputs)
 -- for each input
    for i=1,#inputs do
        -- set neuron value to input value
        self.neurons[1][i]=inputs[i]
    end
    
    -- for each layer (with offset)
    for i=2,#self.layers do
        -- for each neuron
        for j=1,#self.neurons[i] do
        
            local value=0
            
            -- for each neuron in prev layer
            for k=1,#self.neurons[i-1] do
             -- we add weights to a value
                value+=self.weights[i-1][j][k]*self.neurons[i-1][k]
            end
            -- and use tanh activation function
            self.neurons[i][j]=tanh(value)
        end
    end
    
    -- returning output layer
    return self.neurons[#self.neurons]
end

-- mutate function
function nn:mutate()
    -- for each weight in neurons and layers
    for i=1,#self.weights do
        for j=1,#self.weights[i] do
         for k=1,#self.weights[i][j] do
          -- we get weight value and random number
            w=self.weights[i][j][k]
            r=rnd(100)
            
            -- depending on a random num we choose a mutation
            if r<=2 then
                w=-w
            elseif r<=4 then
                w=rnd(1)-0.5
            elseif r<=6 then
                factor=rnd(1)+1
                w*=factor
            elseif r<=8 then
                factor=rnd(1)
                w*=factor
            end
            
            -- then we set a new weight value
            self.weights[i][j][k]=w
         end
        end
    end
end

-- adding fitness
function nn:addfit(f)
    self.fitness+=f
end

-- getting fitness
function nn:getfit()
    return self.fitness
end

function nn:setfit(f)
    self.fitness=f
end

-- neural net vizualization
function nn:draw(_x,_y,_w,_h)
    local gx,gy=_x,_y
    local gw,gh=_w,_h
    
    local neurons={}
    -- getting neurons positions
    for i=1,#self.layers do
        local x_step=gw/#self.layers
        local x=(i-1)*x_step+x_step/2  
        neurons[i]={}
        
        for j=1,self.layers[i] do
            local y_step=gh/self.layers[i]
            local y=(j-1)*y_step+y_step/2
            
            --just for fun
            x+=sin(t/240)*2
            y+=cos((t+i*12)/120)*8
            
            neurons[i][j]={gx+x,gy+y}           
        end
    end
        
    -- drawing connections
    for i=2,#neurons do
        for j=1,#neurons[i] do
            for _j=1,#neurons[i-1] do
            local x1=neurons[i][j][1]
            local y1=neurons[i][j][2]
            local x2=neurons[i-1][_j][1]
        local y2=neurons[i-1][_j][2]
            
            -- draws relation between neurons
            val1=self.neurons[i-1][_j]
            val2=self.neurons[i][j]
            val1+=2.5
            val2+=2.5
            if val1<1 then val1=1 end
            if val1>5 then val1=5 end
            if val2<1 then val2=1 end
            if val2>5 then val2=5 end
            val=(val1+val2)/2
            
            -- draws weights values
            --val=self.weights[i-1][j][_j]
            --val+=0.5
            --val*=5
            --val+=1
            
            if val<1 then val=1 end
            if val>5 then val=5 end
            
            local c=heat_pal[flr(val)] 
            line(x1,y1,x2,y2,c)
            end
        end
    end
    
    -- drawing neurons
    for i=1,#neurons do
        for j=1,#neurons[i] do
            local x=neurons[i][j][1]
            local y=neurons[i][j][2]
            val=self.neurons[i][j]
            val+=2.5
            val=flr(val)
            if val<1 then val=1 end
            if val>5 then val=5 end
            circfill(x,y,2,heat_pal[val])
        end
    end
end

--------------------------------------------------------

-- +------+
-- | ball |
-- +------+

ball={} 

function ball:new(x,y)
    local this={}

    this.x=x
    this.y=y
    
    this.a=0.75
    this.spd=0.5

    self.__index=self
    setmetatable(this,self)
    
    return this
end

function ball:update()
    self.x+=sin(self.a)*self.spd
    self.y+=cos(self.a)*self.spd
end

function ball:draw()
    line(self.x,self.y,self.x+sin(self.a)*8,self.y+cos(self.a)*8,2)
    circfill(self.x,self.y,3,8) 
end

function ball:add_ang(a)
    self.a+=a
end

function ball:set_ang(a)
    self.a=a
end