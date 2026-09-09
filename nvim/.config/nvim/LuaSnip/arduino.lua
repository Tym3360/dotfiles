local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node

local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

-- Arduino Snippets
ls.add_snippets("arduino", {
  -- Basic sketch structure
  s("sketch", fmt([[
#include <Arduino.h>

void setup() {{
  // Initialize serial communication
  Serial.begin({baud});
  
  {}// Initialize pins here
  
}}

void loop() {{
  {}// Main code here
  
}}
]], {
    i(1, "9600"),
    i(2),
    i(3),
  }, { delimiters = "{}" }),

  -- pinMode
  s("pinmode", fmt("pinMode({}, {});", {
    i(1, "PIN"),
    c(2, {
      t("OUTPUT"),
      t("INPUT"),
      t("INPUT_PULLUP"),
    }),
  })),

  -- digitalWrite
  s("dwrite", fmt("digitalWrite({}, {});", {
    i(1, "PIN"),
    c(2, {
      t("HIGH"),
      t("LOW"),
    }),
  })),

  -- digitalRead
  s("dread", fmt("int {} = digitalRead({});", {
    i(1, "value"),
    i(2, "PIN"),
  })),

  -- analogWrite
  s("awrite", fmt("analogWrite({}, {});", {
    i(1, "PIN"),
    i(2, "value"),
  })),

  -- analogRead
  s("aread", fmt("int {} = analogRead({});", {
    i(1, "value"),
    i(2, "PIN"),
  })),

  -- delay
  s("delay", fmt("delay({});", {
    i(1, "1000"),
  })),

  -- millis
  s("millis", fmt("unsigned long {} = millis();", {
    i(1, "startTime"),
  })),

  -- Serial.begin
  s("serial", fmt("Serial.begin({});", {
    c(1, {
      t("9600"),
      t("115200"),
      t("57600"),
    }),
  })),

  -- Serial.print
  s("sprint", fmt("Serial.print({});", {
    i(1, "\"message\""),
  })),

  -- Serial.println
  s("sprintln", fmt("Serial.println({});", {
    i(1, "\"message\""),
  })),

  -- Serial.read
  s("sread", fmt("char {} = Serial.read();", {
    i(1, "incomingByte"),
  })),

  -- if statement
  s("if", fmt([[if ({}) {{
  {}
}}]], {
    i(1, "condition"),
    i(2),
  }, { delimiters = "{}" })),

  -- for loop
  s("for", fmt([[for (int {} = {}; {} < {}; {}++) {{
  {}
}}]], {
    i(1, "i"),
    i(2, "0"),
    rep(1),
    i(3, "10"),
    rep(1),
    i(4),
  }, { delimiters = "{}" })),

  -- while loop
  s("while", fmt([[while ({}) {{
  {}
}}]], {
    i(1, "condition"),
    i(2),
  }, { delimiters = "{}" })),

  -- Function definition
  s("func", fmt([[
{} {}({}) {{
  {}
}}
]], {
    c(1, {
      t("void"),
      t("int"),
      t("float"),
      t("bool"),
      t("char"),
      t("String"),
    }),
    i(2, "functionName"),
    i(3),
    i(4),
  }, { delimiters = "{}" })),

  -- Class definition
  s("class", fmt([[
class {} {{
public:
  {}({}) {{
    {}
  }}
  
  ~{}() {{
    // Destructor
  }}
  
private:
  {}
}};
]], {
    i(1, "ClassName"),
    rep(1),
    i(2),
    i(3),
    rep(1),
    i(4),
  }, { delimiters = "{}" })),

  -- Interrupt
  s("interrupt", fmt([[attachInterrupt(digitalPinToInterrupt({}), {}, {});]], {
    i(1, "PIN"),
    i(2, "ISR"),
    c(3, {
      t("RISING"),
      t("FALLING"),
      t("CHANGE"),
      t("LOW"),
    }),
  })),

  -- ISR
  s("isr", fmt([[void {}() {{
  {}
}}]], {
    i(1, "ISR_NAME"),
    i(2),
  }, { delimiters = "{}" })),

  -- Timer
  s("timer", fmt([[// Timer interrupt
void setupTimer() {{
  // Set up Timer1 for 1Hz interrupt
  noInterrupts();
  TCCR1A = 0;
  TCCR1B = 0;
  TCNT1 = 0;
  OCR1A = 15624;
  TCCR1B |= (1 << WGM12);
  TCCR1B |= (1 << CS12) | (1 << CS10);
  TIMSK1 |= (1 << OCIE1A);
  interrupts();
}}

ISR(TIMER1_COMPA_vect) {{
  {}
}}
]], {
    i(1),
  }, { delimiters = "{}" })),

  -- PWM setup
  s("pwm", fmt([[// Setup PWM on pin {}
void setupPWM() {{
  // Set pin as output
  pinMode({}, OUTPUT);
  
  // Configure Timer2 for PWM
  TCCR2A = (1 << COM2A1) | (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
  TCCR2B = (1 << CS22);
}}
]], {
    i(1, "PIN"),
    rep(1),
  }, { delimiters = "{}" })),
})

-- Also add to cpp filetype for PlatformIO files
ls.add_snippets("cpp", {
  -- Arduino setup in cpp
  s("ardsetup", fmt([[
#include <Arduino.h>

void setup() {{
  Serial.begin({baud});
  {}// Initialize here
}}

void loop() {{
  {}// Main code
}}
]], {
    i(1, "9600"),
    i(2),
    i(3),
  }, { delimiters = "{}" }),
})
