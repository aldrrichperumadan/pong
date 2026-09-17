-- constants
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 640
VIRTUAL_HEIGHT = 360

PADDLE_SPEED = 400
TARGET = 5

push = require 'push'
Class = require 'class'
require 'Paddle'
require 'Ball'

-- run one time at the start of the program
function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong')

    math.randomseed(os.time())

    smallFont = love.graphics.newFont('GeistPixel-Regular-VariableFont_ELSH.ttf', 16)
    largeFont = love.graphics.newFont('GeistPixel-Regular-VariableFont_ELSH.ttf', 32)
    
    love.graphics.setFont(largeFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static')
    }

    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        resizable = true,
        fullscreen = false,
        vsync = true
    })
    push.setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, { upscale = 'normal'})

    player1Score = 0
    player2Score = 0

    servingPlayer = 1

    player1 = Paddle(10, 30, 5,20)
    player2 = Paddle(VIRTUAL_WIDTH - 15, VIRTUAL_HEIGHT - 30, 5, 20)

    ball = Ball(VIRTUAL_WIDTH/2 - 2, VIRTUAL_HEIGHT/ 2 - 2, 4, 4)
    gameState = 'start'
end

function love.resize(w, h)
    push.resize(w, h)
end

-- if a certain key is pressed one time
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'serve'
            ball:reset()

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then
                servingPlayer = 2
            elseif winningPlayer == 2 then
                servingPlayer = 1
            end
        end
    end

end

function love.update(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end

    elseif gameState == 'play' then

        --paddle 1 boundary
        if ball:collides(player1) then
            sounds['paddle_hit']:play()

            ball.dx = -ball.dx * 1.05
            ball.x = player1.x + 5

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        --paddle 2 boundary
        if ball:collides(player2) then
            sounds['paddle_hit']:play()

            ball.dx = -ball.dx * 1.05
            ball.x = player2.x - 4

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        --upper window boundary
        if ball.y <= 0 then
            sounds['wall_hit']:play()

            ball.y = 0
            ball.dy = -ball.dy
            ball.dx = ball.dx * 1.05
        end

        --lower window boundary
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            sounds['wall_hit']:play()

            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            ball.dx = ball.dx * 1.05
        end

        if ball.x < 0 then
            sounds['score']:play()

            servingPlayer = 1
            player2Score = player2Score + 1

            if player2Score == TARGET then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            sounds['score']:play()

            servingPlayer = 2
            player1Score = player1Score + 1;
            if player1Score == TARGET then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end 


    --player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    --player 2 movement
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

-- repeated every 1/60th of second(refreshRate)
function love.draw()
    push.start()
    love.graphics.clear(40/255, 45/255, 52/255, 1)
    love.graphics.setFont(largeFont)
    
    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press enter to begin', 0, 25, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press enter to serve', 0, 25, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        --no ui msg
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.printf('!!Player ' .. tostring(winningPlayer) .. ' wins!!', 0, VIRTUAL_HEIGHT*2/3, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press enter to restart', 0, 25, VIRTUAL_WIDTH, 'center')
    end
    
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH/2 - 55, VIRTUAL_HEIGHT/3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH/2 + 40, VIRTUAL_HEIGHT/3)
    

    displayFPS()
    --paddle 1
    player1:render()

    --paddle 2
    player2:render()

    --ball
    ball:render()
    push.finish()
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 1, 0, 1) --rgb float values, pure green
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(1, 1, 1, 1) --white/translucent
end