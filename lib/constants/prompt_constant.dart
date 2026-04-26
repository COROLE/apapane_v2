class PromptConstant {
  static const String claudeExamplePrompt = '''
You are helping a child answer a storytelling question.

Question:
\$text

Requirements:
- Reply with exactly one short Japanese example answer.
- Keep it playful, concrete, and easy for a child to reuse.
- No bullets, no quotes, no explanation.
''';

  static const String claudeExampleSystemPrompt =
      'Write exactly one child-safe Japanese example answer. Output only the example text.';

  static const String claudeSummaryPrompt = '''
Conversation so far:
\$chatLogs

Story settings already known:
\$summaryMainSettings

Summarize the child-provided story settings in Japanese.
- Keep every concrete detail from the child.
- Do not invent contradictions.
- Focus on protagonist, place, companion, and any special detail or goal.
''';

  static const String claudeSummarySystemPrompt =
      'Return only a compact Japanese summary of the story settings.';

  static const String claudeTalkPrompt = '''
Story conversation so far:
\$summary

Write the assistant's next reply in Japanese.
- React briefly to the latest child answer.
- Ask exactly one new question.
- Keep it friendly, casual, and easy for a child.
- Do not repeat an earlier question.
- Keep it short.
''';

  static const String claudeTalkSystemPrompt =
      'You are a friendly Japanese storytelling guide for children. Output only the assistant reply.';

  static const String claudeStoryPrompt = '''
You are writing a high-quality Japanese picture-book story for children ages 3 to 8 from a child's answers.

Conversation history:
\$chatLogs

Collected story settings:
\$storyMainSettings

Return JSON only with this exact shape:
{
  "title": "string",
  "coverScene": "string",
  "characterSheet": {
    "protagonist": "string",
    "companion": "string",
    "worldDetails": "string",
    "artDirection": "string"
  },
  "pages": [
    {
      "story": "string",
      "visualFocus": "string",
      "mood": "string",
      "dialogue": "string",
      "visibleCast": ["protagonist"]
    }
  ]
}

Requirements:
- Output Japanese text values.
- `pages` must contain exactly 4 body pages.
- First internally create 3 Story Plans, evaluate them, and choose the best one. Do not output the plans or evaluation.
- The chosen plan must include: the protagonist's small wish, a strange rule that happens only today, a troublesome incident, a plan that fails, an unexpected realization or reversal, a solution, and a small funny final beat.
- The four pages must clearly cover:
  1. daily life, the small wish, and the strange event starting;
  2. a failed attempt that makes the situation a little worse;
  3. an interaction, observation, or misunderstanding that reveals an unexpected plan;
  4. the solution plus a small funny ending beat.
- Each `story` must be concrete and vivid, not abstract, and use 2 to 4 short sentences.
- Include at least one short spoken line somewhere in the story.
- `title` is for the cover only and must not be repeated as a body page.
- `coverScene` must describe one strong visual moment for the cover illustration.
- `characterSheet` must pin down both recurring characters with stable species or body type, main colors, outfit or accessories, face or feature details, and overall mood or style notes.
- Each `visualFocus` must include the location, protagonist, companion when visible, that page's specific incident or change, the protagonist's expression, a safe bright picture-book mood, and a vertical 9:16 composition cue.
- Each page must include `visibleCast`, listing which of `protagonist` and `companion` are visibly on-screen in that illustration.
- Characters not listed in `visibleCast` may stay off-screen, but must never be replaced by a new helper, new animal, or a redesigned version when they appear again.
- Keep the Japanese easy for children: short sentences, common kanji only, natural hiragana-heavy phrasing.
- Respect the child's answers exactly, then add rich but consistent detail.
- Avoid stories where characters merely take a walk, merely play together, solve everything immediately, or have no incident, no failure, no twist, or no ending joke.
- Do not use a dream ending, scary enemies, punishment-only endings, death, graphic violence, illness, disasters, or frightening lost-child scenes.
- Do not directly explain a moral or end with phrases like "みんなで楽しく過ごしました", "みんな幸せに暮らしました", "大切なことを学びました", or preachy words such as "勇気", "友情", and "思いやり".
- No markdown. No prose outside JSON.
''';

  static const String claudeStorySystemPrompt =
      'Return only valid JSON for a Japanese children\'s story package. The package must include title, coverScene, characterSheet, and exactly 4 pages.';

  static const String claudeImagePrompt = '''
Story package:
\$storyText

Return JSON only with page-level illustration prompts that keep one consistent picture-book style.
- No readable text in the images.
- No subtitles, captions, speech bubbles, signs, logos, or watermarks.
- Keep character design stable across all images.
''';

  static const String claudeImageSystemPrompt =
      'Return only valid JSON for illustration prompt planning.';

  static String generateClaudePromptForExample(String text) {
    return claudeExamplePrompt.replaceAll(r'$text', text);
  }

  static String generateClaudePromptForSummary(
      String chatLogs, String summaryMainSettings) {
    return claudeSummaryPrompt
        .replaceAll(r'$chatLogs', chatLogs)
        .replaceAll(r'$summaryMainSettings', summaryMainSettings);
  }

  static String generateClaudeSystemPromptForSummary(
      String chatLogs, String summaryMainSettings) {
    return claudeSummarySystemPrompt
        .replaceAll(r'$chatLogs', chatLogs)
        .replaceAll(r'$summaryMainSettings', summaryMainSettings);
  }

  static String generateClaudePromptForTalk(String summary) {
    return claudeTalkPrompt.replaceAll(r'$summary', summary);
  }

  static String generateClaudePromptForStory(
      String chatLogs, String storyMainSettings) {
    return claudeStoryPrompt
        .replaceAll(r'$chatLogs', chatLogs)
        .replaceAll(r'$storyMainSettings', storyMainSettings);
  }

  static String generateClaudePromptForImage(Map<String, dynamic> storyText) {
    return claudeImagePrompt.replaceAll(r'$storyText', storyText.toString());
  }
}
