double scoreP1(List<double> input) => 0.6;
double scoreP2(List<double> input) => 0.7;
double scoreP3(List<double> input) => 0.8;
double scoreP4(List<double> input) => 0.5;
double scoreP6(List<double> input) => 0.65;

// HAND-WRITTEN — Social Accountability scorecard
double scoreP7(List<double> input) {
  const w = [0.15, 0.12, 0.10, 0.10, 0.08, 0.10, 0.08, 0.12, 0.10, 0.05];
  double s = 0.0;
  for (int i = 0; i < 10; i++) {
    s += input[i] * w[i];
  }
  return s.clamp(0.0, 1.0);
}

// HAND-WRITTEN — Tax & Compliance scorecard
double scoreP8(List<double> input) {
  const w = [0.25, 0.15, 0.20, 0.15, 0.10, 0.08, 0.07];
  double s = 0.0;
  for (int i = 0; i < 7; i++) {
    s += input[i] * w[i];
  }
  return s.clamp(0.0, 1.0);
}

double scoreP5(List<double> input) {
  if (input[0] < 0.5 || input[1] < 0.5) return 0.0; // KYC GATE
  const w = [0.15,0.15,0.10,0.08,0.08,0.06,0.05,0.04,0.03,0.06,0.04,0.04,0.02,0.02,0.02,0.03,0.02,0.01];
  double s = 0.0;
  for (int i = 0; i < 18; i++) {
    s += input[i] * w[i];
  }
  return s.clamp(0.0, 1.0);
}


