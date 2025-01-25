include image
include world

# Game constants
WIDTH = 1000
HEIGHT = 500
GROUND = 450
# Character constants
CHARACTER-WIDTH = 40
CHARACTER-HEIGHT = 60
CHARACTER-COLOR = "black"
JUMP-VELOCITY = -17
GRAVITY = 1.5
# Obstacle constants
OBSTACLE-WIDTH = 50
OBSTACLE-HEIGHT = 50
OBSTACLE-COLOR = "grey"
INITIAL-OBSTACLE-SPEED = 10  
SPEED-INCREASE = 2          
SPEED-INCREASE-INTERVAL = 2 
data GameState:
  | playing(
      char-x :: Number,
      char-y :: Number,
      velocity :: Number,
      obstacle-x :: Number,
      score :: Number,
      obstacle-speed :: Number)  # Added obstacle speed to state
  | game-over(score :: Number)
end

fun initial-state():
  # Start character at ground level
  playing(100, GROUND - CHARACTER-HEIGHT, 0, WIDTH, 0, INITIAL-OBSTACLE-SPEED)
end

fun draw-state(s):
  cases(GameState) s:
    | playing(char-x, char-y, velocity, obstacle-x, score, obstacle-speed) =>
      # Start with empty scene
      game-scene = empty-scene(WIDTH, HEIGHT)
      
      # Draw game title
      scene-with-title = put-image(
        text("PIXEL JUMP", 36, "black"),
        WIDTH / 2,
        HEIGHT - 50,
        game-scene)
      
      # Draw ground
      scene-with-ground = put-image(
        rectangle(WIDTH, 2, "solid", "black"),
        WIDTH / 2,
        HEIGHT - GROUND,
        scene-with-title)
      
      # Draw character
      scene-with-char = put-image(
        rectangle(CHARACTER-WIDTH, CHARACTER-HEIGHT, "solid", CHARACTER-COLOR),
        char-x,
        HEIGHT - (char-y + (CHARACTER-HEIGHT / 2)),
        scene-with-ground)
      
      # Draw obstacle
      scene-with-obstacle = put-image(
        rectangle(OBSTACLE-WIDTH, OBSTACLE-HEIGHT, "solid", OBSTACLE-COLOR),
        obstacle-x,
        HEIGHT - (GROUND - (OBSTACLE-HEIGHT / 2)),
        scene-with-char)
        
      # Draw score and speed
      scene-with-score = put-image(
        text(string-append("Score: ", num-to-string(score)), 24, "black"),
        50,
        HEIGHT - 30,
        scene-with-obstacle)
        
      # Add speed indicator
      put-image(
        text(string-append("Speed: ", num-to-string(obstacle-speed)), 24, "black"),
        200,
        HEIGHT - 30,
        scene-with-score)
        
    | game-over(score) =>
      base-scene = empty-scene(WIDTH, HEIGHT)
      
      scene-with-title = put-image(
        text("PIXEL JUMP", 36, "black"),
        WIDTH / 2,
        HEIGHT - 50,
        base-scene)
      
      scene-with-text = put-image(
        text("Game Over!", 36, "black"),
        WIDTH / 2,
        HEIGHT - ((HEIGHT / 2) - 50),
        scene-with-title)
      
      scene-with-score = put-image(
        text(string-append("Final Score: ", num-to-string(score)), 24, "black"),
        WIDTH / 2,
        HEIGHT - (HEIGHT / 2),
        scene-with-text)
      
      put-image(
        text("Press 'R' to restart", 24, "black"),
        WIDTH / 2,
        HEIGHT - ((HEIGHT / 2) + 50),
        scene-with-score)
  end
end

fun key-update(s, key):
  cases(GameState) s:
    | playing(char-x, char-y, velocity, obstacle-x, score, obstacle-speed) =>
      # Handle jumping (check against ground position)
      new-velocity = if (key == " ") and (char-y >= (GROUND - CHARACTER-HEIGHT)):
        JUMP-VELOCITY
      else:
        velocity
      end
      
      playing(char-x, char-y, new-velocity, obstacle-x, score, obstacle-speed)
      
    | game-over(score) =>
      if key == "r":
        initial-state()
      else:
        s
      end
  end
end

fun calculate-new-speed(score, current-speed):
  if num-modulo(score, SPEED-INCREASE-INTERVAL) == 0:
    current-speed + SPEED-INCREASE
  else:
    current-speed
  end
end

fun tick-update(s):
  cases(GameState) s:
    | playing(char-x, char-y, velocity, obstacle-x, score, obstacle-speed) =>
      # Update velocity and position
      new-velocity = velocity + GRAVITY
      
      # Calculate new position and ensure character doesn't fall through ground
      new-y = num-min(
        GROUND - CHARACTER-HEIGHT,
        char-y + new-velocity)
      
      # Update obstacle position
      new-obstacle-x = if obstacle-x < (0 - OBSTACLE-WIDTH):
        WIDTH
      else:
        obstacle-x - obstacle-speed
      end
      
      # Update score and speed
      new-score = if obstacle-x < (0 - OBSTACLE-WIDTH):
        score + 1
      else:
        score
      end

      # Calculate new speed based on score
      new-speed = if obstacle-x < (0 - OBSTACLE-WIDTH):
        calculate-new-speed(new-score, obstacle-speed)
      else:
        obstacle-speed
      end
      
      playing(char-x, new-y, new-velocity, new-obstacle-x, new-score, new-speed)
      
    | game-over(score) => s
  end
end

fun check-collision(s):
  cases(GameState) s:
    | playing(char-x, char-y, velocity, obstacle-x, score, obstacle-speed) =>
      char-left = char-x - (CHARACTER-WIDTH / 2)
      char-right = char-x + (CHARACTER-WIDTH / 2)
      char-top = char-y
      char-bottom = char-y + CHARACTER-HEIGHT
      
      obstacle-left = obstacle-x - (OBSTACLE-WIDTH / 2)
      obstacle-right = obstacle-x + (OBSTACLE-WIDTH / 2)
      obstacle-top = GROUND - OBSTACLE-HEIGHT
      obstacle-bottom = GROUND
      
      if not(
        (char-right < obstacle-left) or
        (char-left > obstacle-right) or
        (char-bottom < obstacle-top) or
        (char-top > obstacle-bottom)):
        game-over(score)
      else:
        s
      end
      
    | game-over(score) => s
  end
end

fun game-tick(s):
  check-collision(tick-update(s))
end

big-bang(initial-state(), [
  list:
    to-draw(draw-state),
    on-key(key-update),
    on-tick(game-tick)])