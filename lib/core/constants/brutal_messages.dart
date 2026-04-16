class BrutalMessages {
  static const List<String> painConfirmation = [
    "Open it... but remember distractions compound too.",
    "Every tap trains weakness.",
    "Comfort now, regret later.",
    "Your future self is watching this choice.",
    "Dreams die in tiny daily decisions.",
    "The version of you that succeeds doesn't do this.",
    "Another notification won't make you happy.",
    "You're trading your future for a dopamine drip.",
    "This is the exact moment discipline is built—or broken.",
    "Average people open it. You wanted to be exceptional.",
    "The cost is invisible until it's too late.",
    "Your attention is the most valuable thing you own.",
  ];

  static const List<String> countdownMessages = [
    "Urges fade when not fed.",
    "Discipline is built in moments like this.",
    "10 seconds can save 1 hour.",
    "You still have time to cancel.",
    "Strong people wait. Weak people react.",
    "The urge will pass. It always does.",
    "Your streak is worth more than this.",
    "Breathe. You don't actually need this.",
  ];

  static const List<String> streakMotivation = [
    "Your focus is sharpening.",
    "The monk inside you is winning.",
    "Silence beats noise. Keep going.",
    "Every day resisted is a day earned.",
    "You're building a mind others can't touch.",
  ];

  static const List<String> streakWarnings = [
    "You're slipping. Reclaim your focus.",
    "The algorithm is winning. Fight back.",
    "You came here to be different. Act like it.",
    "Weak days compound into weak years.",
    "This is the pattern you said you'd break.",
  ];

  static const List<String> dashboardQuotes = [
    "The obstacle is the way.",
    "Discipline equals freedom.",
    "Win the morning. Win the day.",
    "Do the hard thing. Especially when you don't want to.",
    "Your future self is built in moments like this.",
    "Protect your focus like your life depends on it.",
    "Boredom is a gateway to greatness.",
    "The monk trains when no one is watching.",
    "Stillness is not emptiness. It is power.",
  ];

  static const List<String> resistedMessages = [
    "You resisted. That was strength.",
    "Urge defeated. Streak intact.",
    "The monk wins again.",
    "That decision will compound.",
    "Well done. Now get back to work.",
  ];

  static String getRegretMessage(
      String appName, int lastSessionMinutes, int weeklyHours) {
    final messages = [
      "Last time you opened $appName, you stayed $lastSessionMinutes minutes.",
      "This week $appName has taken $weeklyHours hours from your life.",
      "You said you'd focus today.",
      "Every minute here is a minute not building your future.",
    ];
    messages.shuffle();
    return messages.first;
  }
}
