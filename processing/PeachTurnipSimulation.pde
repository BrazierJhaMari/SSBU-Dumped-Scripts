// Peach Turnip Simulation (Processing - Java mode)
// Visual simulator of Peach's Down Special (Turnip) RNG & behaviors
// Controls:
//   G - Pick/Roll a turnip
//   T - Throw the held turnip
//   P - Plant the held turnip (drops in place)
//   R - Reroll (pick a fresh turnip)
//   S - Toggle display of probabilities
//   Up/Down - change RNG seed
//   Space - toggle auto-pick mode
//   L - show recent log entries
//   E - export log to processing/log.txt
//   1/2/3 - increase probability for variant 1/2/3
//   !/@/# (Shift+1/2/3) - decrease probability for variant 1/2/3

Turnip held = null;
ArrayList<Turnip> world;
ArrayList<Explosion> explosions;
boolean showProbs = true;
boolean autoPick = false;
long seed = 0;
float gravity = 0.6;

// Default probabilities (sum to 1.0)
// prob2 -> Mr. Saturn, prob3 -> Bomb
float prob1 = 0.33; // normal Turnip (Variant 1)
float prob2 = 0.33; // Mr. Saturn (fun rare item)
float prob3 = 0.33; // Bomb (acts like a bomb item)
float probGiant = 0.01; // rare giant turnip (adjustable)

// logging
ArrayList<String> logEntries = new ArrayList<String>();
int maxLogDisplay = 10;

void setup(){
  size(900, 500);
  world = new ArrayList<Turnip>();
  explosions = new ArrayList<Explosion>();
  seed = System.currentTimeMillis() & 0xffffffffL;
  textFont(createFont("Arial", 14));
  // Create a simple fighter to receive effects
  fighter = new Fighter(width*0.65, height-120);
}

void draw(){
  background(245);
  // ground
  fill(200, 255, 200);
  rect(0, height-120, width, 120);

  // Draw Peach placeholder
  drawPeach();

  // Update and draw world turnips
  for(int i = world.size()-1; i >= 0; i--){
    Turnip t = world.get(i);
    t.update();
    t.draw();
    if(t.toRemove || t.isOffscreen()) world.remove(i);
  }

  // Update and draw explosions
  for(int i = explosions.size()-1; i >= 0; i--){
    Explosion e = explosions.get(i);
    e.update();
    e.draw();
    if(e.finished) explosions.remove(i);
  }

  // Update and draw fighter
  if(fighter != null){
    fighter.update();
    fighter.draw();
  }

  // Draw held turnip near Peach
  if(held != null){
    pushMatrix();
    translate(200, height-200);
    held.drawHeld();
    popMatrix();
  }

  drawUI();

  if(autoPick && held == null){
    pickTurnip();
  }
}

void drawPeach(){
  // simple peach silhouette
  pushMatrix();
  translate(140, height-200);
  noStroke();
  fill(255, 200, 220);
  ellipse(0, -40, 80, 120); // body
  fill(255, 220, 230);
  ellipse(0, -95, 60, 60); // head
  fill(255, 160, 180);
  rect(-40, -20, 20, 40); // arm
  popMatrix();
}

void drawUI(){
  fill(30);
  textAlign(LEFT, TOP);
  text("Peach Turnip Simulator (Processing Java)", 12, 12);

  String heldTxt = (held == null) ? "None" : held.getDisplayName();
  text("Held: " + heldTxt, 12, 40);

  text("Seed: " + seed + "  (Up/Down to change)", 12, 60);
  text("Auto-pick (Space): " + (autoPick?"ON":"OFF"), 12, 80);

  text("Controls: G=Pick, T=Throw, P=Plant, R=Reroll, S=ToggleProbs", 12, 110);

  if(showProbs){
    textAlign(RIGHT, TOP);
    float y = 12;
    text("Probabilities:", width-20, y);
    y += 20;
    text(String.format("Variant1: %.2f", prob1), width-20, y); y+=18;
    text(String.format("Variant2: %.2f", prob2), width-20, y); y+=18;
    text(String.format("Variant3: %.2f", prob3), width-20, y); y+=18;
    text(String.format("Giant: %.4f", probGiant), width-20, y); y+=18;
  }

  textAlign(LEFT, TOP);
  text("World objects: " + world.size(), 12, height-140);

  // helpful hints
  textAlign(CENTER, BOTTOM);
  text("Hold a turnip: pick (G). Throw it (T) to send it into the world. Plant it (P) to drop it.", width/2, height-10);
}

void keyPressed(){
  if(key == 'g' || key == 'G') pickTurnip();
  if(key == 'r' || key == 'R') pickTurnip();
  if(key == 't' || key == 'T') throwTurnip();
  if(key == 'p' || key == 'P') plantTurnip();
  if(key == 's' || key == 'S') showProbs = !showProbs;
  if(keyCode == UP) seed++;
  if(keyCode == DOWN) seed--;
  if(key == ' ') autoPick = !autoPick;
  if(key == 'l' || key == 'L') {
    // print recent log
    for(String s : logEntries) println(s);
  }
  if(key == 'e' || key == 'E'){
    // export log
    String[] out = new String[logEntries.size()];
    logEntries.toArray(out);
    saveStrings("processing/log.txt", out);
    println("Exported log to processing/log.txt");
  }
  // probability tuning
  if(key == '1') { prob1 += 0.05; normalizeProbs(); }
  if(key == '2') { prob2 += 0.05; normalizeProbs(); }
  if(key == '3') { prob3 += 0.05; normalizeProbs(); }
  if(key == '!') { prob1 = max(0, prob1 - 0.05); normalizeProbs(); }
  if(key == '@') { prob2 = max(0, prob2 - 0.05); normalizeProbs(); }
  if(key == '#') { prob3 = max(0, prob3 - 0.05); normalizeProbs(); }
  // fighter controls
  if(key == '0'){
    // reset fighter
    if(fighter != null) fighter.reset();
  }
  if(key == 'h' || key == 'H'){
    if(fighter != null) fighter.heal(10);
  }
}

void pickTurnip(){
  if(held != null) return; // already holding
  // determinstic RNG based on seed and system time
  long localSeed = seed ^ (System.nanoTime() & 0xffffffffL);
  float r = RandomFloat(localSeed);
  // normalize clamps
  float total = prob1 + prob2 + prob3 + probGiant;
  float c = r * total;
  TurnipType type;
  if(c < prob1) type = TurnipType.V1;
  else if(c < prob1 + prob2) type = TurnipType.MR_SATURN;
  else if(c < prob1 + prob2 + prob3) type = TurnipType.BOMB;
  else type = TurnipType.GIANT;
  held = new Turnip(type);
  // log pick
  String log = String.format("Pick: seed=%d -> %s", seed, held.getDisplayName());
  logEntries.add(0, log);
  if(logEntries.size() > 200) logEntries.remove(logEntries.size()-1);
}

void throwTurnip(){
  if(held == null) return;
  // create thrown copy
  Turnip t = held.copy();
  t.throwFrom(200, height-200, random(-6, -2), random(6, 10));
  // if bomb, set fuse
  if(t.type == TurnipType.BOMB) t.fuseTimer = 90; // 90 frames ~1.5s
  t.thrown = true;
  world.add(t);
  held = null;
}

void plantTurnip(){
  if(held == null) return;
  Turnip t = held.copy();
  t.plantAt(200, height-200);
  // planted bombs: shorter fuse
  if(t.type == TurnipType.BOMB) t.fuseTimer = 60;
  world.add(t);
  held = null;
}

float RandomFloat(long s){
  // simple xorshift-ish for reproducibility
  long x = s & 0xffffffffL;
  x ^= (x << 13);
  x ^= (x >> 17);
  x ^= (x << 5);
  x = x & 0xffffffffL;
  return (x & 0xffffffffL) / (float)0xffffffffL;
}

enum TurnipType { V1, MR_SATURN, BOMB, GIANT }

class Turnip {
  TurnipType type;
  float x, y;
  float vx, vy;
  float size;
  color col;
  boolean planted = false;
  boolean heldVisual = false;
  boolean toRemove = false;
  boolean thrown = false;
  int fuseTimer = -1; // for bombs

  Turnip(TurnipType t){
    type = t;
    vx = 0; vy = 0;
    size = getBaseSize(t);
    col = getColorForType(t);
  }

  Turnip copy(){
    Turnip nt = new Turnip(type);
    nt.size = size;
    nt.col = col;
    return nt;
  }

  void throwFrom(float sx, float sy, float ang, float speed){
    x = sx; y = sy;
    vx = speed * (ang > 0 ? 1 : -1) * 0.7;
    vy = ang; // negative is upward
    planted = false;
  }

  void plantAt(float px, float py){
    x = px; y = py;
    planted = true;
    vx = 0; vy = 0;
  }

  void update(){
    if(planted){
      // planted items do nothing for now
      return;
    }
    vy += gravity;
    x += vx;
    y += vy;
    // simple bounce on ground
    float groundY = height-120;
    if(y > groundY){
      // landed
      y = groundY;
      // if bomb and thrown, explode on impact
      if(type == TurnipType.BOMB && thrown){
        explode();
        return;
      }
      // mr saturn landing effect
      if(type == TurnipType.MR_SATURN && thrown){
        mrSaturnLand();
      }
      vy *= -0.35;
      vx *= 0.85;
      // small friction to stop
      if(abs(vy) < 1) vy = 0;
      if(abs(vx) < 0.2) vx = 0;
    }

    // fuse handling for bombs
    if(type == TurnipType.BOMB && fuseTimer > -1){
      fuseTimer--;
      if(fuseTimer <= 0){
        explode();
        return; // exploded
      }
    }
    // collision with fighter when thrown
    if(thrown && fighter != null && !toRemove){
      float d = dist(x, y, fighter.x, fighter.y);
      if(d < (size*0.5 + fighter.radius)){
        // hit fighter
        if(type == TurnipType.BOMB){
          explode();
          return;
        } else if(type == TurnipType.MR_SATURN){
          // Mr. Saturn heals slightly when thrown at fighter
          fighter.heal(5);
          logEntries.add(0, "Mr. Saturn healed the fighter (+5)");
          toRemove = true;
          return;
        } else {
          // normal turnip: small damage and knockback
          fighter.applyHit(6, (fighter.x - x) * 0.2, -6);
          logEntries.add(0, "Turnip hit fighter: -6 HP");
          toRemove = true;
          return;
        }
      }
    }
  }

  // custom drawing per type implemented below (kept for held and world)

  boolean isOffscreen(){
    return x < -200 || x > width+200 || y > height+200;
  }

  String getDisplayName(){
    switch(type){
      case V1: return "Turnip (Variant 1)";
      case MR_SATURN: return "Mr. Saturn";
      case BOMB: return "Bomb";
      case GIANT: return "Giant Turnip";
    }
    return "Turnip";
  }

  float getBaseSize(TurnipType t){
    switch(t){
      case V1: return 28;
      case MR_SATURN: return 20; // small
      case BOMB: return 34; // slightly rounder than normal
      case GIANT: return 110;
    }
    return 32;
  }

  color getColorForType(TurnipType t){
    switch(t){
      case V1: return color(220, 120, 120);
      case MR_SATURN: return color(255, 220, 100); // yellowish Saturn
      case BOMB: return color(40, 40, 40); // black bomb
      case GIANT: return color(255, 200, 80);
    }
    return color(200);
  }

  // custom drawing per type
  void draw(){
    pushMatrix();
    translate(x, y);
    noStroke();
  if(type == TurnipType.MR_SATURN){
      // Mr. Saturn: small lemon/yellow with simple face
      fill(col);
      ellipse(0, 0, size, size*0.9);
      fill(30);
      ellipse(-size*0.15, -size*0.05, size*0.12, size*0.12); // left eye
      ellipse(size*0.15, -size*0.05, size*0.12, size*0.12); // right eye
      rectMode(CENTER);
      fill(120, 40, 40);
      rect(0, size*0.12, size*0.35, size*0.12, 4); // mouth
  } else if(type == TurnipType.BOMB){
      // Bomb: black round with small fuse
      fill(col);
      ellipse(0, 0, size, size);
      // fuse
      stroke(180, 80, 20);
      strokeWeight(3);
      line(-size*0.15, -size*0.45, -size*0.4, -size*0.8);
      noStroke();
      fill(255, 120, 0);
      ellipse(-size*0.4, -size*0.8, size*0.12, size*0.12);
    } else {
      // default turnip / giant
      fill(col);
      ellipse(0, 0, size, size*0.9);
      // simple leaf
      fill(100, 160, 40);
      ellipse(-size*0.25, -size*0.35, size*0.4, size*0.2);
    }
    popMatrix();
  }

  void drawHeld(){
    pushMatrix();
    noStroke();
  if(type == TurnipType.MR_SATURN){
      fill(col);
      ellipse(0, 0, size, size*0.9);
      fill(30);
      ellipse(-size*0.15, -size*0.05, size*0.12, size*0.12);
      ellipse(size*0.15, -size*0.05, size*0.12, size*0.12);
      fill(120, 40, 40);
      rectMode(CENTER);
      rect(0, size*0.12, size*0.35, size*0.12, 4);
  } else if(type == TurnipType.BOMB){
      fill(col);
      ellipse(0, 0, size, size);
      stroke(180, 80, 20);
      strokeWeight(3);
      line(-size*0.15, -size*0.45, -size*0.4, -size*0.8);
      noStroke();
      fill(255, 120, 0);
      ellipse(-size*0.4, -size*0.8, size*0.12, size*0.12);
    } else {
      fill(col);
      ellipse(0, 0, size, size*0.9);
      fill(100, 160, 40);
      ellipse(-size*0.25, -size*0.35, size*0.4, size*0.2);
    }
    popMatrix();
  }

  void explode(){
    // spawn visual explosion and mark for removal
    explosions.add(new Explosion(x, y, max(40, size*1.5)));
    // log
    logEntries.add(0, String.format("Bomb exploded at (%.1f,%.1f)", x, y));
    if(logEntries.size() > 200) logEntries.remove(logEntries.size()-1);
    // apply chain effects to nearby turnips and fighter
    float radius = max(40, size*1.5);
    for(Turnip other : world){
      if(other == this) continue;
      if(other.toRemove) continue;
      float d = dist(x, y, other.x, other.y);
      if(d <= radius * 1.0){
        // if other is a bomb, trigger it soon (chain)
        if(other.type == TurnipType.BOMB){
          if(other.fuseTimer < 0 || other.fuseTimer > 10) other.fuseTimer = 10;
          logEntries.add(0, String.format("Chain: bomb at (%.1f,%.1f) set to fuse", other.x, other.y));
        } else {
          // push non-bombs away
          float nx = other.x - x;
          float ny = other.y - y;
          float nd = max(0.1, sqrt(nx*nx + ny*ny));
          other.vx += (nx/nd) * 6.0 / (1 + other.size/30.0);
          other.vy += (ny/nd) * 4.0 / (1 + other.size/30.0);
        }
      }
    }
    // affect fighter
    if(fighter != null){
      float df = dist(x, y, fighter.x, fighter.y);
      if(df <= radius*1.6){
        float power = map(max(0, radius*1.6 - df), 0, radius*1.6, 0, 40);
        // direction
        float kx = fighter.x - x;
        float ky = fighter.y - y - 20; // slight upward
        float kd = max(0.1, sqrt(kx*kx + ky*ky));
        fighter.applyHit(power*0.8, (kx/kd)*power*0.06, -abs(ky/kd)*power*0.06);
        logEntries.add(0, String.format("Fighter hit by explosion: -%.0f HP", power*0.8));
      }
    }
    if(logEntries.size() > 200) logEntries.remove(logEntries.size()-1);
    // mark for removal
    toRemove = true;
  }

  void mrSaturnLand(){
    // small random effect: either a tiny heal or a funny bounce
    float r = random(1);
    if(r < 0.5){
      logEntries.add(0, "Mr. Saturn: emits cheerful chirp (no game effect simulated)");
    } else {
      // bounce a little
      vy = -6;
      vx = random(-2, 2);
      logEntries.add(0, "Mr. Saturn: bounces away playfully");
    }
    if(logEntries.size() > 200) logEntries.remove(logEntries.size()-1);
  }
}

class Explosion{
  float x, y, r;
  int life = 24;
  boolean finished = false;
  Explosion(float x, float y, float r){ this.x = x; this.y = y; this.r = r; }
  void update(){ life--; if(life <= 0) finished = true; }
  void draw(){
    pushMatrix();
    translate(x, y);
    float t = (24 - life) / 24.0;
    noStroke();
    fill(255, 180, 60, 200*(1-t));
    ellipse(0, 0, r * t, r * t);
    popMatrix();
  }
}

void normalizeProbs(){
  // keep probGiant small; normalize the other three to sum to (1 - probGiant)
  float remain = max(0.0, 1.0 - probGiant);
  float s = prob1 + prob2 + prob3;
  if(s <= 0){ prob1 = remain/3; prob2 = remain/3; prob3 = remain/3; return; }
  prob1 = prob1 / s * remain;
  prob2 = prob2 / s * remain;
  prob3 = prob3 / s * remain;
}

// Simple fighter simulation
Fighter fighter;

class Fighter{
  float x, y;
  float vx = 0, vy = 0;
  float radius = 28;
  float health = 100;
  Fighter(float x, float y){ this.x = x; this.y = y; }
  void update(){
    vy += gravity*0.9;
    x += vx; y += vy;
    float groundY = height-120;
    if(y > groundY){
      y = groundY; vy = 0; vx *= 0.8;
    }
    // clamp
    x = constrain(x, 0+radius, width-radius);
  }
  void draw(){
    pushMatrix();
    translate(x, y);
    // body
    fill(180, 100, 240);
    ellipse(0, -20, radius*1.6, radius*1.8);
    // head
    fill(240, 200, 220);
    ellipse(0, -50, radius, radius);
    // health
    popMatrix();
    // draw health bar
    fill(40);
    rect(x - 40, y - 90, 80, 10);
    fill(200, 40, 40);
    rect(x - 40, y - 90, map(health, 0, 100, 0, 80), 10);
    fill(0);
    textAlign(CENTER, BOTTOM);
    text(String.format("HP: %.0f", health), x, y - 95);
  }
  void applyHit(float damage, float kx, float ky){
    health -= damage;
    vx += kx;
    vy += ky;
    if(health < 0) health = 0;
  }
  void heal(float v){ health = min(100, health + v); }
  void reset(){ health = 100; x = width*0.65; y = height-120; vx = vy = 0; }
}
