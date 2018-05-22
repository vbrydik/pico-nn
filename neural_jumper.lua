function _init()
    world_speed=-1          -- speed of the world
    world_offset=0          -- for graphics
    world_objects={}        -- all world objects (obstacle and robots)
    
    heat_pal={1,2,8,14,7}   -- nn palette
    
    population=5            -- number of networks and robots per geneation
    robots={}
    networks={}
    
    max_fit_net=nil         -- network with biggest fit
    max_fit_val=0
    generation=0
    
    -- initializing game and particles
    init_game()
    init_particles()
    
    robot_focused=1
    rf_x,rf_y=0,0
    
    show_nn=true
    show_info=true
    show_menu=false
    menu_opt=1
    
    t=0
end

function init_game(net)
    -- resetting speed and objects
    world_speed=-1
    world_objects={}

    -- resetting obstacle
    o=obstacle:new(136,112,8,8)

    -- getting the max fit neural network
    if net!=nil then
        if net:getfit()>max_fit_val then
            max_fit_net=nn:make_copy_of(net)
            max_fit_val=net:getfit()
        end
    end
    
    -- resetting robots and networks 
    robots={}
    networks={}
    
    -- creating robots and networks
    for i=1,population do
        -- creating robots
        local x=16+6*(i-1)
        local y=104
        local r=robot:new(x,y,1)
        add(robots,r)
        
        -- creating networks
        if net==nil then
            -- if we didnt pass a network
            -- we create one from scratch
            local n=nn:new({3,5,3})
            n:init_neurons()
            n:init_weights()
            add(networks,n)
        else
            -- if we passed a network
            -- we create copy of it
         local n=nn:make_copy_of(max_fit_net)   
         
         -- then we mutate it and reset fitness
         n:mutate()
         n:setfit(0)
            add(networks,n)
        end
    end

    generation+=1
end

function _update60()
    
    -- you can kill a robot if you're bored lol
    if btnp(❎) and show_menu==false then
        local f=robot_focused
        robots[f]:die()
    end
    
    update_menu()
    set_focused_robot()
    
    -- checking if all robots are dead
    local all_dead=true
    for r in all(robots) do
        if r.dead==false then
            all_dead=false
        end
    end
    -- if all robots are dead, init game again
    -- but with giving a network with the biggest fitness
    if all_dead then
        init_game(get_net_by_fit())
    end
    
    -- updating obstacle
    o:update()
    
    -- updating robots and networks
    for i=#robots,1,-1 do
        local r=robots[i]
        -- if robot is not dead
        if r.dead==false then
        -- updating a robot
        r:update()
        
        -- updating its network
        local n=networks[i]
        res=n:feed_forward(
            {
                mid(0,(o.x-r.x)/128,1),
                mid(0,o.h/24,1),
                mid(0,(-world_speed)/1.75,1)
            }
        )
        
        -- adding fit and getting class
        n:addfit(1/600)
        class=get_class(res)
        
        -- doing some actions depending on class
        if class==2 then
            r:do_jump(-1.4)
        elseif class==3 then
            r:do_jump(-1.8)
        end
    end
    end

    -- world speed stuff    
    if t%60==0 then
        world_speed-=0.01
        world_speed=max(world_speed,-1.75)
    end
    
    -- updating particles
    update_particles()
    
    t+=1
    world_offset+=world_speed
end

function _draw()
    cls()
    
    -- particles
    draw_particles()
    
    -- floor
    for i=-1,16 do
        spr(9 ,i*8+world_offset%8,112)
        spr(10,i*8+world_offset%8,120)  
    end
    
    -- network
    if show_nn then
    fillp(0b01011010010110100101)
    --get_net_by_fit():draw(4,20,120,64)
    networks[robot_focused]:draw(4,20,120,64)
    fillp()
    end
    
    -- robots
    for i=1,#robots do
        local r=robots[i]
        r:draw()
        -- drawing focus thinhy
        draw_focus(r,i)
    end
    
    -- obstacle
    o:draw()
    -- menu
    draw_menu()
    -- debug data   
    draw_info()
end


------------------------


function draw_focus(r,i)
 if i==robot_focused and show_nn then
        palt(0,false)
        palt(3,true)
        rf_x=lerp(rf_x,r.x,0.25)
        spr(17,rf_x+1,r.my+10)
        palt()
        
        local str="robot #"..i
        print(str,rf_x+11,r.my+11,0)
        print(str,rf_x+12,r.my+12,0)
        print(str,rf_x+11,r.my+13,0)
        print(str,rf_x+10,r.my+12,0)
        print(str,rf_x+11,r.my+12,7)
    end
end


function update_menu()
 if show_menu then
        if btnp(⬆️) then
            menu_opt-=1
        end
        if btnp(⬇️) then
            menu_opt+=1
        end
        menu_opt=mid(1,menu_opt,3)
    
        if btnp(❎) then
            if menu_opt==1 then
             show_nn=not(show_nn)
            elseif menu_opt==2 then
                show_info=not(show_info)
            elseif menu_opt==3 then
                show_menu=false
            end
        end
    end
    
    if btnp(🅾️) then
        show_menu=not(show_menu)
        menu_opt=1
    end
end


function draw_menu()
    fillp()
    print("menu🅾️",104,7,7)
    print("kill❎",104,1,7)
        
    if show_menu then
        rectfill(80,14,128,42,0)
        rect(80,14,128,42,8)
        print(">",84,18+(menu_opt-1)*8,8)
        if show_nn then
            print("hide nn",90,18,7)
        else
            print("show nn",90,18,7)
        end
        if show_info then
            print("hide info",90,26,7)
        else
         print("show info",90,26,7)
        end
        print("exit menu",90,34,7)
    end
end


function draw_info()
    if show_info then
    local cur_fit_val=get_net_by_fit():getfit()
    
    print("max_fit|cur_fit|gen|",1,1,6)
    
    local tmp_str=""
    local max_str=""
    local cur_str=""
    local gen_str=""
    
    tmp_str=tmp_str..flr(max_fit_val*100)/100
    for i=1,7-#tmp_str do max_str=max_str.." " end
    max_str=max_str..tmp_str.."|"
    tmp_str=""
    
    tmp_str=tmp_str..flr(cur_fit_val*100)/100
    for i=1,5-#tmp_str do cur_str=cur_str.." " end
    cur_str=cur_str..tmp_str.."|"
    tmp_str=""
    
    tmp_str=tmp_str..generation
    for i=1,3-#tmp_str do gen_str=gen_str.." "  end
    gen_str=gen_str..tmp_str.."|"
        
    print(max_str,1,7,7)
    print(cur_str,41,7,7)
    print(gen_str,65,7,7)
    end
end

---------------------------------------------------------

-- +-------------+
-- | robot class |
-- +-------------+

robot={}

function robot:new(x,y,s)
    local this={}
    
    this.x=x
    this.y=y        -- current y
    this.my=y   -- ground y
    this.dy=0 -- current y delta
    this.s=0
    this.anim={1,2,1,3, --run anim
               2,4}     -- jump and fall
    this.t=0
    
    this.grv=0.05
    this.jump_spd=-1.6
    
    this.jump=false
    this.grounded=true
    this.name="robot"
    
    this.coll={
        x=1,
        y=0,
        w=6,
        h=7,
    }
    this.collided=false
    this.dead=false
    
    -- for graphics (trails)
    this.trails={}
    
    self.__index=self
    setmetatable(this,self)
    
    add(world_objects,this)
    
    expl_part_spawn(this.x+4,this.y+4,3)    
    return this
end

function robot:update()
    -- ground detection
    if self.y==self.my then
        self.grounded=true
    else
     self.grounded=false
    end
    
    -- jumping
    if self.jump and self.grounded then
        self.dy=self.jump_spd
        self.jump=false
        self.grounded=false
    end
    
    -- acceleration
    if self.grounded==false then
        self.y+=self.dy
        self.dy+=self.grv
    end
    
    -- land
    if self.y>self.my then
        self.dy=0
        self.y=self.my
        self.grounded=true
        self.s=3
        -- land particles here
        land_part_spawn(self.x+4,self.y+8,2,8)
    end
    
    -- collision detection
    for i=1,#world_objects do
        local o=world_objects[i]
        --if o!=self then
        if self.name!=o.name then
            self.collided=collide(self,o)
        end
        --end
    end
    
    -- animation
    if self.t%8==0 then
        local last_s=self.s
        self.s%=4
        self.s+=1
        if self.grounded then
            -- do walk particles here
            step_part_spawn(self.x+3,self.y+8,2)
        end
    end
    
    -- rise and fall animation
    if self.grounded==false then
        if self.dy<=0 then
            self.s=5
        else
            self.s=6
        end
    end
    
    -- if collided
    if self.collided then
        -- do some particles here
     expl_part_spawn(self.x+4,self.y+4,4)
        self.dead=true
    end
    
    -- graphics (trails)
    for i=#self.trails,1,-1 do
        local t=self.trails[i]
        t.x+=world_speed
        t.t-=1
        if t.t<=0 then
            del(self.trails,t)
        end 
    end
    
    if self.t%4==0 then
        local t={}
        t.x=self.x+3
        t.y=self.y
        t.t=24
        --t.dx=world_speed
        add(self.trails,t)
    end
    
    -- increasing counter
    self.t+=1
end

function robot:draw()
    if self.dead then return end
    spr(self.anim[self.s],self.x,self.y)
    
    local col=11
    
    for i=#self.trails,2,-1 do
        local t1=self.trails[i]
        local t2=self.trails[i-1]
        
        if t1.t<20 then col=3 end
        if t1.t<12 then col=1 end
        
        line(t1.x,t1.y,t2.x,t2.y,col)
    end
    local ft=self.trails[#self.trails]
    line(ft.x,ft.y,self.x+3,self.y,11)
end

function robot:do_jump(spd)
    if self.grounded then
     self.jump_spd=spd
        self.jump=true
        land_part_spawn(self.x+4,self.y+8,2,1)
    end
end

function robot:die()
    expl_part_spawn(self.x+4,self.y+4,4)
    self.dead=true
end

----------------------------------------------------------

-- +----------------+
-- | obstacle class |
-- +----------------+

obstacle={}

function obstacle:new(x,y,w,h)
    local this={}
    
    this.x=x
    this.my=y
    this.y=y-h
    this.w=w
    this.h=h
    
    this.name="obstacle"
    
    this.coll={
        x=0,
        y=0,
        w=w,
        h=h,
    }
    this.collided=false
    
    self.__index=self
    setmetatable(this,self)
    
    add(world_objects,this)
    
    return this
end

function obstacle:update()
    if self.x<0-self.w then
        local h=1+flr(rnd(3))
        h*=8
        self.x=128+world_offset%8
        self.y=self.my-h
        
        self.h=h
        self.coll.h=h
    end
    
    self.x+=world_speed
end

function obstacle:draw()
    local x,y=self.x+self.coll.x,self.y+self.coll.y

    for i=1,self.h/8 do
        palt(0,false)
        spr(8,x,y+(i-1)*8)
        palt()
    end
end

------------------------------------------------------------------

-- +------------+
-- | some tools |
-- +------------+

-- collision detection
function collide(a,b)
 return (
    a.x+a.coll.x<b.x+b.coll.x+b.coll.w and
    b.x+b.coll.x<a.x+a.coll.x+a.coll.w and
    a.y+a.coll.y<b.y+b.coll.y+b.coll.h and
    b.y+b.coll.y<a.y+a.coll.y+a.coll.h
 )
end

-- hiberbolic tangent function
function tanh(x)
    return sinh(x)/cosh(x)
end

function cosh(x)
    return 0.5*(exp(x)-exp(-x))
end

function sinh(x)
    return 0.5*(exp(x)+exp(-x)) 
end

function exp(x)
    local e=2.71828183
    return e^x
end

-- class extract
function get_class(out)
    local idx=1
    
    for i=2,#out do
        local o=out[i]
        if o>out[idx] then idx=i end
    end
    
    return idx
end


function get_net_by_fit()
    local idx=1
    
    for i=2,#networks do
        local f=networks[i]:getfit()
        if f>networks[idx]:getfit() then idx=i end
    end
    
    return networks[idx]
end


function set_focused_robot()
    local rf=robot_focused
    local d=0
    
    if btnp(⬅️) then
        d=-1
    end
    if btnp(➡️) then
     d=1
    end
    
    local all_dead=true
    for r in all(robots) do
        if r.dead==false then
            all_dead=false
        end
    end
    
    if not all_dead then
    if robots[rf].dead then
        local l=false
        local c=population+1
        while l==false do
            rf+=1
            if rf>population then rf=1 end
            if rf<1 then rf=population end
            l=not(robots[rf].dead)
        end
    else
        local l=false
    
    while l==false do
        rf+=d
        if rf>population then rf=1 end
        if rf<1 then rf=population end
        l=not(robots[rf].dead)
    end
    end
 end
    
    rf=mid(1,rf,population)
    robot_focused=rf
end

function lerp(a,b,t)
    return a+(b-a)*t
end

------------------------------------------------------

-- +----------------+
-- | neural network |
-- +----------------+

nn={} -- nn short for neural networlk

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

-------------------------------------------------------------------

-- +-------------------+
-- | particles section |
-- +-------------------+

function init_particles()
    step_parts={}
    land_parts={}
    expl_parts={}
end

function update_particles()
 -- step particles
    for i=#step_parts,1,-1 do
        local p=step_parts[i]
        
        p.x+=p.dx
        p.y+=p.dy
        
        if p.t<0 then
            del(step_parts,p)
        end
        
        p.t-=1
    end
    
    -- land particles
    for i=#land_parts,1,-1 do
        local p=land_parts[i]
        
        p.x+=sin(p.a)*p.spd+world_speed/2
        p.y+=cos(p.a)*p.spd
        
        if p.t<0 then
            del(land_parts,p)
        end
        
        p.t-=1
    end
    
    -- expl particles
    for i=#expl_parts,1,-1 do
        local p=expl_parts[i]
        
        p.x+=sin(p.a)*p.spd+world_speed
        p.y+=cos(p.a)*p.spd
        
        if p.t<0 then
            del(expl_parts,p)
        end
        
        p.t-=1
    end
end

function draw_particles()
    -- step particles
    for i=#step_parts,1,-1 do
        local p=step_parts[i] -- *(p.t/p.dt)
        local c=7
        local d=p.t/p.dt
        
        if d<0.75 then
            c=6
        end
        if d<0.5 then
         c=5
         fillp(0b0011000011000000)
        end
        if d<0.25 then
         c=1
         fillp(0b0101101001011010)
        end
        
        circfill(p.x,p.y,p.r,c)
        fillp()
    end
    
    -- land particles
    for i=#land_parts,1,-1 do
        local p=land_parts[i]
        local c=7
        local d=p.t/p.dt
        
        if d<0.75 then
            c=6
        end
        if d<0.5 then
         c=5
         fillp(0b0011000011000000)
        end
        if d<0.25 then
         c=1
         fillp(0b0101101001011010)
        end
        
        circfill(p.x,p.y,p.r*d*2,c)
    end

    -- land particles
    for i=#expl_parts,1,-1 do
        local p=expl_parts[i]
        local c=7
        local d=p.t/p.dt
        
        if d<0.75 then
            c=6
        end
        if d<0.5 then
         c=5
         fillp(0b0011000011000000)
        end
        if d<0.25 then
         c=1
         fillp(0b0101101001011010)
        end
        
        circfill(p.x,p.y,p.r*d*2,c)
    end
end

function step_part_spawn(x,y,r)
    local p={}
    local t=flr(rnd(8))+8
    p.x=x
    p.y=y
    p.r=r
    p.dx=world_speed/4+rnd(0.8)-0.8
    p.dy=-rnd(0.4)+0.1
    p.t=t
    p.dt=t
    add(step_parts,p)
end

function land_part_spawn(x,y,r,n)
    for i=1,n do
        local p={}
        local t=flr(rnd(16))+16
        p.x=x+1-rnd(2)
        p.y=y
        p.r=r
        p.a=rnd(0.5)+0.25
        p.spd=0.25+rnd(0.7)
        p.t=t
        p.dt=t
        add(land_parts,p)
    end
end

function expl_part_spawn(x,y,r)
    for i=1,flr(rnd(10)+10) do
        local p={}
        local t=flr(rnd(16))+16
        p.x=x+1-rnd(2)
        p.y=y
        p.r=r
        p.a=rnd(1)
        p.spd=0.5+rnd(1)
        p.t=t
        p.dt=t
        add(expl_parts,p)
    end
end