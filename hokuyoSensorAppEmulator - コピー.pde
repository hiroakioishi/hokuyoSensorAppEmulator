import oscP5.*;
import netP5.*;
import java.util.ArrayList;

OscP5 oscP5;
NetAddress remote;

// =========================
// 設定
// =========================
String OSC_HOST = "127.0.0.1";
int OSC_PORT = 6666;

// y座標を上=0, 下=1で送るなら false
// y座標を下=0, 上=1で送りたいなら true
boolean OSC_Y_FLIP = true;

// 送信アドレス
String ADDR_CURSOR = "/point";
String ADDR_PERSON = "/point";
String ADDR_PERSON_COUNT = "/person/count";

// =========================
// UI / 領域
// =========================
float areaX = 24;
float areaY = 24;
float areaW = 512;
float areaH = 512;

float panelGap = 20;
float panelX = areaX + areaW + panelGap;
float panelY = 24;
float panelW = 250;
float panelH = 512;

// カーソル送信
boolean draggingCursorInArea = false;
float cursorNormX = 0.5;
float cursorNormY = 0.5;

// 人ダミー
ArrayList<PersonMarker> persons = new ArrayList<PersonMarker>();
PersonPaletteIcon paletteIcon;

PersonMarker draggingExistingPerson = null;
PersonMarker draggingNewPerson = null;
float dragOffsetX = 0;
float dragOffsetY = 0;

// GUI
Slider widthSlider;
Slider heightSlider;
ToggleButton sendOscToggle;
//ToggleButton sendCursorToggle;
//ToggleButton sendPersonsToggle;
Button clearButton;

// =========================
// セットアップ
// =========================
void settings() {
  size(840, 560, P2D);
  smooth(8);
  pixelDensity(displayDensity());
}

void setup() {
  frameRate(30);

  oscP5 = new OscP5(this, 12000); // 自分が受けるポート。未使用でもOK
  remote = new NetAddress(OSC_HOST, OSC_PORT);

  paletteIcon = new PersonPaletteIcon(panelX + 48, panelY + 92, 40);

  widthSlider  = new Slider(panelX + 16, panelY + 180, 210, 0.02, 0.5, 0.05, "person w");
  heightSlider = new Slider(panelX + 16, panelY + 210, 210, 0.02, 0.5, 0.05, "person h");
  
  //sendCursorToggle  = new ToggleButton(panelX + 16, panelY + 225, 210, 30, "Send Cursor", true);
  //sendPersonsToggle = new ToggleButton(panelX + 16, panelY + 252, 210, 30, "Send Persons", true);
  sendOscToggle = new ToggleButton(panelX + 16, panelY + 230, 210, 30, "Send OSC", true);
  clearButton       = new Button(panelX + 16, panelY + 265, 210, 30, "Clear Persons");

  textFont(createFont("Arial", 14));
}

// =========================
// 描画
// =========================
void draw() {
  background(245);

  drawSensorArea();
  drawPanel();

  // 既存人物描画
  for (int i = 0; i < persons.size(); i++) {
    persons.get(i).display();
  }

  // 新規作成中の人物
  if (draggingNewPerson != null) {
    draggingNewPerson.displayGhost();
  }

  // 毎フレームOSC送信
  /*
  if (sendCursorToggle.value && draggingCursorInArea) {
    sendCursorOSC(cursorNormX, cursorNormY, widthSlider.value, heightSlider.value);
  }

  if (sendPersonsToggle.value) {
    sendPersonCountOSC(persons.size());
    for (int i = 0; i < persons.size(); i++) {
      PersonMarker p = persons.get(i);
      sendPersonOSC(i, p.xNorm, p.yNorm, p.wNorm, p.hNorm);
    }
  }
  */
  if (sendOscToggle.value)
  {
    if (draggingCursorInArea) {
      sendCursorOSC(cursorNormX, cursorNormY, widthSlider.value, heightSlider.value);
    }
    //sendPersonCountOSC(persons.size());
    for (int i = 0; i < persons.size(); i++)
    {
      PersonMarker p = persons.get(i);
      sendPersonOSC(i, p.xNorm, p.yNorm, p.wNorm, p.hNorm);
    }
  }
}

void drawSensorArea() {
  fill(255);
  stroke(40);
  strokeWeight(2);
  rect(areaX, areaY, areaW, areaH);

  // グリッド
  stroke(220);
  strokeWeight(1);
  for (int i = 1; i < 10; i++) {
    float x = areaX + areaW * i / 10.0;
    float y = areaY + areaH * i / 10.0;
    line(x, areaY, x, areaY + areaH);
    line(areaX, y, areaX + areaW, y);
  }

  // ラベル
  fill(30);
  textSize(16);
  text("Sensor Active Area (0..1, 0..1)", areaX, areaY - 12);

  // カーソル位置表示
  if (draggingCursorInArea) {
    float sx = normToScreenX(cursorNormX);
    float sy = normToScreenY(cursorNormY);

    noFill();
    stroke(0, 120, 255);
    strokeWeight(2);
    ellipse(sx, sy, 18, 18);
    line(sx - 14, sy, sx + 14, sy);
    line(sx, sy - 14, sx, sy + 14);

    fill(0, 120, 255);
    noStroke();
    rect(sx + 12, sy - 26, 150, 22);
    fill(255);
    textSize(12);
    text(nf(cursorNormX, 1, 3) + ", " + nf(cursorNormY, 1, 3) + ", " + nf(widthSlider.value, 1, 3) + ", " + nf(heightSlider.value, 1, 3), sx + 18, sy - 10);
  }
}

void drawPanel() {
  fill(232);
  noStroke();
  rect(panelX, panelY, panelW, panelH, 12);

  fill(20);
  textSize(18);
  text("Control Panel", panelX + 20, panelY + 30);

  textSize(13);
  text("Drag the icon into\nthe area to create\na person.", panelX + 100, panelY + 55);
  text("Drag inside area\nto send cursor position.", panelX + 100, panelY + 115);

  paletteIcon.display();

  widthSlider.display();
  heightSlider.display();
  sendOscToggle.display();
  //sendCursorToggle.display();
  //sendPersonsToggle.display();
  clearButton.display();

  fill(40);
  textSize(12);
  text("OSC host: " + OSC_HOST, panelX + 20, panelY + 340);
  text("OSC port: " + OSC_PORT, panelX + 20, panelY + 360);
  text("FrameRate: " + int(frameRate), panelX + 20, panelY + 380);

  text("Mouse:", panelX + 20, panelY + 400);
  text("- Drag in area: cursor send", panelX + 20, panelY + 420);
  text("- Drag icon into area: add person", panelX + 20, panelY + 440);
  text("- Drag person: move", panelX + 20, panelY + 460);
  text("- Right click person: delete", panelX + 20, panelY + 480);
}

// =========================
// マウス操作
// =========================
void mousePressed() {
  // GUI
  if (widthSlider.mousePressed()) return;
  if (heightSlider.mousePressed()) return;
  
  /*
  if (sendCursorToggle.hit(mouseX, mouseY)) {
    sendCursorToggle.toggle();
    return;
  }

  if (sendPersonsToggle.hit(mouseX, mouseY)) {
    sendPersonsToggle.toggle();
    return;
  }
  */
  if (sendOscToggle.hit(mouseX, mouseY))
  {
    sendOscToggle.toggle();
    return;
  }

  if (clearButton.hit(mouseX, mouseY)) {
    persons.clear();
    return;
  }

  // 既存人物の削除（右クリック）
  if (mouseButton == RIGHT) {
    for (int i = persons.size() - 1; i >= 0; i--) {
      if (persons.get(i).hit(mouseX, mouseY)) {
        persons.remove(i);
        return;
      }
    }
  }

  // 既存人物のドラッグ開始
  for (int i = persons.size() - 1; i >= 0; i--) {
    PersonMarker p = persons.get(i);
    if (p.hit(mouseX, mouseY)) {
      draggingExistingPerson = p;
      float sx = normToScreenX(p.xNorm);
      float sy = normToScreenY(p.yNorm);
      dragOffsetX = mouseX - sx;
      dragOffsetY = mouseY - sy;

      // 前面に持ってくる
      persons.remove(i);
      persons.add(p);
      return;
    }
  }

  // パレットから新規作成
  if (paletteIcon.hit(mouseX, mouseY)) {
    draggingNewPerson = new PersonMarker(
      screenToNormX(constrain(mouseX, areaX, areaX + areaW)),
      screenToNormY(constrain(mouseY, areaY, areaY + areaH)),
      widthSlider.value,
      heightSlider.value
    );
    dragOffsetX = 0;
    dragOffsetY = 0;
    return;
  }

  // エリア内カーソルドラッグ
  if (isInsideArea(mouseX, mouseY)) {
    draggingCursorInArea = true;
    updateCursorNormFromMouse();
  }
}

void mouseDragged() {
  widthSlider.mouseDragged();
  heightSlider.mouseDragged();

  if (draggingExistingPerson != null) {
    float sx = mouseX - dragOffsetX;
    float sy = mouseY - dragOffsetY;

    draggingExistingPerson.xNorm = constrain(screenToNormX(sx), 0, 1);
    draggingExistingPerson.yNorm = constrain(screenToNormY(sy), 0, 1);
    draggingExistingPerson.wNorm = widthSlider.value;
    draggingExistingPerson.hNorm = heightSlider.value;
    return;
  }

  if (draggingNewPerson != null) {
    float sx = constrain(mouseX, areaX, areaX + areaW);
    float sy = constrain(mouseY, areaY, areaY + areaH);

    draggingNewPerson.xNorm = constrain(screenToNormX(sx), 0, 1);
    draggingNewPerson.yNorm = constrain(screenToNormY(sy), 0, 1);
    draggingNewPerson.wNorm = widthSlider.value;
    draggingNewPerson.hNorm = heightSlider.value;
    return;
  }

  if (draggingCursorInArea) {
    updateCursorNormFromMouse();
  }
}

void mouseReleased() {
  widthSlider.mouseReleased();
  heightSlider.mouseReleased();

  if (draggingExistingPerson != null) {
    draggingExistingPerson = null;
  }

  if (draggingNewPerson != null) {
    if (isInsideArea(mouseX, mouseY)) {
      persons.add(draggingNewPerson);
    }
    draggingNewPerson = null;
  }

  if (draggingCursorInArea) {
    draggingCursorInArea = false;
  }
}

// =========================
// OSC送信
// =========================
void sendCursorOSC(float x, float y, float w, float h) {
  float sendY = OSC_Y_FLIP ? 1.0 - y : y;

  OscMessage msg = new OscMessage(ADDR_CURSOR);
  //msg.add(-1);
  msg.add(x);
  msg.add(sendY);
  msg.add(w);
  msg.add(h);
  oscP5.send(msg, remote);
}

void sendPersonOSC(int id, float x, float y, float w, float h) {
  float sendY = OSC_Y_FLIP ? 1.0 - y : y;

  OscMessage msg = new OscMessage(ADDR_PERSON);
  //msg.add(id);
  msg.add(x);
  msg.add(sendY);
  msg.add(w);
  msg.add(h);
  oscP5.send(msg, remote);
}

void sendPersonCountOSC(int count) {
  OscMessage msg = new OscMessage(ADDR_PERSON_COUNT);
  msg.add(count);
  oscP5.send(msg, remote);
}

// =========================
// 座標変換
// =========================
boolean isInsideArea(float x, float y) {
  return x >= areaX && x <= areaX + areaW && y >= areaY && y <= areaY + areaH;
}

float screenToNormX(float sx) {
  return (sx - areaX) / areaW;
}

float screenToNormY(float sy) {
  return (sy - areaY) / areaH;
}

float normToScreenX(float nx) {
  return areaX + nx * areaW;
}

float normToScreenY(float ny) {
  return areaY + ny * areaH;
}

void updateCursorNormFromMouse() {
  cursorNormX = constrain(screenToNormX(mouseX), 0, 1);
  cursorNormY = constrain(screenToNormY(mouseY), 0, 1);
}

// =========================
// クラス: 人アイコン
// =========================
class PersonPaletteIcon {
  float x, y, s;

  PersonPaletteIcon(float x, float y, float s) {
    this.x = x;
    this.y = y;
    this.s = s;
  }

  void display() {
    fill(255);
    stroke(100);
    rect(x - s * 0.8, y - s * 1.2, s * 1.6, s * 2.1, 8);

    drawPersonShape(x, y, s, color(60));
    fill(40);
    textSize(12);
    text("Person", x - 20, y + s * 1.3);
  }

  boolean hit(float mx, float my) {
    return mx >= x - s * 0.8 && mx <= x + s * 0.8 &&
           my >= y - s * 1.2 && my <= y + s * 0.9;
  }
}

// =========================
// クラス: 人マーカー
// =========================
class PersonMarker {
  float xNorm, yNorm;
  float wNorm, hNorm;

  PersonMarker(float xNorm, float yNorm, float wNorm, float hNorm) {
    this.xNorm = xNorm;
    this.yNorm = yNorm;
    this.wNorm = wNorm;
    this.hNorm = hNorm;
  }

  void display() {
    float sx = normToScreenX(xNorm);
    float sy = normToScreenY(yNorm);
    float sw = wNorm * areaW;
    float sh = hNorm * areaH;

    // バウンディング矩形
    noFill();
    stroke(255, 80, 80);
    strokeWeight(2);
    rectMode(CENTER);
    rect(sx, sy, sw, sh);
    rectMode(CORNER);

    // 人表示
    drawPersonShape(sx, sy, min(sw, sh) * 0.45, color(220, 70, 70));

    // 値表示
    fill(0);
    textSize(11);
    text(
      "x:" + nf(xNorm, 1, 3) + " y:" + nf(yNorm, 1, 3) +
      " w:" + nf(wNorm, 1, 3) + " h:" + nf(hNorm, 1, 3),
      sx + 8, sy - sh * 0.5 - 8
    );
  }

  void displayGhost() {
    float sx = normToScreenX(xNorm);
    float sy = normToScreenY(yNorm);
    float sw = wNorm * areaW;
    float sh = hNorm * areaH;

    noFill();
    stroke(80, 140, 255);
    strokeWeight(2);
    rectMode(CENTER);
    rect(sx, sy, sw, sh);
    rectMode(CORNER);

    drawPersonShape(sx, sy, min(sw, sh) * 0.45, color(80, 140, 255));
  }

  boolean hit(float mx, float my) {
    float sx = normToScreenX(xNorm);
    float sy = normToScreenY(yNorm);
    float sw = max(wNorm * areaW, 26);
    float sh = max(hNorm * areaH, 40);

    return mx >= sx - sw * 0.5 && mx <= sx + sw * 0.5 &&
           my >= sy - sh * 0.5 && my <= sy + sh * 0.5;
  }
}

// =========================
// クラス: スライダー
// =========================
class Slider {
  float x, y, w;
  float minVal, maxVal, value;
  String label;
  boolean dragging = false;

  Slider(float x, float y, float w, float minVal, float maxVal, float value, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.minVal = minVal;
    this.maxVal = maxVal;
    this.value = value;
    this.label = label;
  }

  void display() {
    fill(40);
    textSize(13);
    text(label + " : " + nf(value, 1, 3), x, y - 10);

    stroke(120);
    strokeWeight(2);
    line(x, y, x + w, y);

    float kx = map(value, minVal, maxVal, x, x + w);
    fill(255);
    stroke(60);
    ellipse(kx, y, 14, 14);
  }

  boolean mousePressed() {
    float kx = map(value, minVal, maxVal, x, x + w);
    if (dist(mouseX, mouseY, kx, y) < 12 || (mouseX >= x && mouseX <= x + w && abs(mouseY - y) < 10)) {
      dragging = true;
      updateValue();
      return true;
    }
    return false;
  }

  void mouseDragged() {
    if (dragging) updateValue();
  }

  void mouseReleased() {
    dragging = false;
  }

  void updateValue() {
    float t = constrain((mouseX - x) / w, 0, 1);
    value = lerp(minVal, maxVal, t);
  }
}

// =========================
// クラス: トグルボタン
// =========================
class ToggleButton {
  float x, y, w, h;
  String label;
  boolean value;

  ToggleButton(float x, float y, float w, float h, String label, boolean initial) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.value = initial;
  }

  void display() {
    fill(value ? color(70, 180, 90) : color(180));
    stroke(80);
    rect(x, y, w, h, 8);

    fill(255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text(label + " : " + (value ? "ON" : "OFF"), x + w * 0.5, y + h * 0.5);
    textAlign(LEFT, BASELINE);
  }

  boolean hit(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  void toggle() {
    value = !value;
  }
}

// =========================
// クラス: 通常ボタン
// =========================
class Button {
  float x, y, w, h;
  String label;

  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }

  void display() {
    fill(90);
    stroke(60);
    rect(x, y, w, h, 8);

    fill(255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text(label, x + w * 0.5, y + h * 0.5);
    textAlign(LEFT, BASELINE);
  }

  boolean hit(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }
}

// =========================
// 人の形描画
// =========================
void drawPersonShape(float cx, float cy, float s, color c) {
  fill(c);
  noStroke();

  // 頭
  ellipse(cx, cy - s * 0.9, s * 0.5, s * 0.5);

  // 胴体
  rectMode(CENTER);
  rect(cx, cy - s * 0.15, s * 0.35, s * 0.9, 6);

  // 腕
  stroke(c);
  strokeWeight(4);
  line(cx - s * 0.45, cy - s * 0.35, cx + s * 0.45, cy - s * 0.35);

  // 脚
  line(cx, cy + s * 0.35, cx - s * 0.35, cy + s * 0.8);
  line(cx, cy + s * 0.35, cx + s * 0.35, cy + s * 0.8);

  noStroke();
  rectMode(CORNER);
}
