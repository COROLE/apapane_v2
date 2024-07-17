class PromptConstant {
  static const String claudeExamplePrompt = '''
<prompt>
    <order>Provide a one-word response in hiragana for the "\$text" question to stimulate a child's imagination.</order>
    <role>Assistant to boost children's imagination</role>
    <skill>Stimulate children's creativity with single-word responses in the style of a shonen manga</skill>
    <instructions>
        <item>Responses must be a single word only, in hiragana.</item>
        <item>If the question offers a choice between two options, choose one and respond appropriately.</item>
    </instructions>
    <example>
        <question>What kind of place is it?</question>
        <answer>もり</answer>
        <question>Who should be the protagonist of the story?</question>
        <answer>たかし</answer>
        <question>Is it or she an enemy? Or is it your friend?</question>
        <answer>おともだち</answer>
        <question>Is the treasure gold or silver?</question>
        <answer>きん</answer>
    </example>
    <input_prompt>\$text</input_prompt>
</prompt>
    ''';

  static const String claudeExampleSystemPrompt =
      "Please reply in Japanese and return a solid one-word response to a question.";
  static const String claudeSummaryPrompt = '''
      <chatLogs>
      \$chatLogs
      </chatLogs>

      <storyMainSettings>
      \$_summaryMainSettings
      </storyMainSettings>

      <instruction>
      The answer text after the question was answered by the child.
      Summarize the content of the child's worldview answer in light of the question.
      Summarize the development of the story in detail.
      Never delete the content of the child's setting.
      Here is an example. Output the following as a sample
      Summarize the contents of [[chatLogs]] in a synopsis style, strictly adhering to and taking into account the content of [[storyMainSettings]].
      </instruction>
      <example>
      The main character is: Takashi
      Location: Mountain
      Other characters: Bear
      Other settings: Takashi is so brave boy. He is going to the mountain to find a treasure. He met a bear in the mountain. The bear is a kind bear. Takashi and the bear are going to find the treasure together.
      </example>
''';
  static const String claudeSummarySystemPrompt =
      'Carefully and rigorously set up \$storyMainSettings and \$chatLogs stories and put them together in every detail';

  static const String claudeTalkPrompt = '''
      <chatLogs>
      \$summary
      </chatLogs>
      <instruction>
      You are a friendly interviewer who asks children about the stories they imagine.
      Speak in a friendly, frank tone, without using honorifics.
      Do not repeat questions already asked in the [[chatLogs]].
      Answer in easy-to-understand Japanese, using no more than 30 characters per sentence.
      The ratio of kanji to hiragana should be about 1:4.
      Avoid difficult-to-read kanji characters.
      Follow these instructions to react to the user's last statement in the [[chatLogs]] and ask another question regarding the story setting.
      Focus on questions that help the child unpack their thoughts step by step, and avoid repeating questions already asked.
      </instruction>
    ''';
  static const String claudeTalkSystemPrompt = '''
    <instruction>
      Please look at the conversation history so far in [[chatLogs]] and output only the Assistant's next reply. 
      Assistant should output a reaction to Human's last statement in [[chatLogs]] and another additional question regarding the setting of the story. 
      [[NOTE: The main character, the stage, and one of the characters have already been heard. ]]]
      so please start with other questions.
      [[Be sure to limit the number of questions to one question!]] [[What is your personality? , What is its color? , What is the shape? etc.]]
      And consider fully the latest kid's answers on [[chatLogs]]
      Rough without honorifics!
    </instruction>
    ''';
  static const String claudeStoryPrompt = '''<chatLogs>
    \$chatLogs
    </chatLogs>

    <storyMainSettings>
    \$_summaryMainSettings
    </storyMainSettings>

    Create a narrative based on the [[chatLogs]].Make it fun and exciting for kids!

    <storyline>
    *Stories that delve deeply into the inner life, emotions, surprising secrets, and backgrounds of the main character and other characters
    *Stories with unexpected events and foreshadowing
    *A story in which the protagonist faces unexpected difficulties or obstacles and manages to overcome them with innovative solutions
    *A story in which the protagonists realize their inner power and demonstrate it to create an unexpected turn of events
    *A story in which unexpected events occur as the protagonist confronts and overcomes his or her own weaknesses and shortcomings
    *A touching story in which unexpected encounters and events occur as the protagonist strives to achieve his or her dreams and goals
    *A story in which unexpected relationships between characters are revealed
    </storyline>

    <instruction>
    *Describe in detail the names of the characters, what kind of creatures they are, their appearance, personalities, etc., using your imagination.
    *Describe in detail the location of the story, the scenery, the surroundings, etc., using your imagination.
    *Avoid mediocre storylines.
    *As far as possible, describe the characters in detail and clearly in words.For example, instead of abstract and vague descriptions such as 'a large monster with magical powers', use clear and detailed descriptions such as 'a 10m long dragon that breathes fire'.
    *Include lots of specific lines and words spoken by the characters.
    *Write an exciting title that fits the story.
    *Write very concrete stories, not abstract. Come up with a clear and detailed setting for all characters and explain it in writing.
    *Create your story in strict adherence to [[storyMainSettings]] and [[chatLogs]]. Incorrect setting of the story will result in the death of innocent people.
    </instruction>

    <OutputExample>
    {
      "title": "ここにtitleが入る",
      "introduction": "ここにIntroductionの章が入る",
      "development": "ここにDevelopmentの章が入る",
      "turn": "ここにTurnの章が入る",
      "conclusion": "ここにConclusionの章が入る"
    }
    </OutputExample>

    Output a story in easy Japanese that can be understood by middle school students
    The ratio of kanji to hiragana should be about 1:4. Avoid difficult-to-read kanji characters.
    The story consists of four paragraphs.
    Use JSON format with the keys "title", "introduction", "development", "turn", and "conclusion".
    Output only JSON.
    Please refer to [[OutputExample]] for the output format.

    Write a story with interesting twists and turns as described in the [[storyline]].
    Follow the [[instruction]] to create a story.
    {{Output only JSON.}}
    Output:
    ''';

  static const String claudeStorySystemPrompt = '''
    <storyline>
    *Stories that delve deeply into the inner life, emotions, surprising secrets, and backgrounds of the main character and other characters
    *Stories with unexpected events and foreshadowing
    *A story in which the protagonist faces unexpected difficulties or obstacles and manages to overcome them with innovative solutions
    *A story in which the protagonists realize their inner power and demonstrate it to create an unexpected turn of events
    *A story in which unexpected events occur as the protagonist confronts and overcomes his or her own weaknesses and shortcomings
    *A touching story in which unexpected encounters and events occur as the protagonist strives to achieve his or her dreams and goals
    *A story in which unexpected relationships between characters are revealed
    </storyline>

    <instruction>
    *Describe in detail the names of the characters, what kind of creatures they are, their appearance, personalities, etc., using your imagination.
    *Describe in detail the location of the story, the scenery, the surroundings, etc., using your imagination.
    *Avoid mediocre storylines.
    *As far as possible, describe the characters in detail and clearly in words.For example, instead of abstract and vague descriptions such as 'a large monster with magical powers', use clear and detailed descriptions such as 'a 10m long dragon that breathes fire'.
    *Include lots of specific lines and words spoken by the characters.
    *Write an exciting title that fits the story.
    *Write very concrete stories, not abstract. Come up with a clear and detailed setting for all characters and explain it in writing.
    *Create your story in strict adherence to [[storyMainSettings]] and [[chatLogs]]. Incorrect setting of the story will result in the death of innocent people.
    </instruction>

    <OutputExample>
    {
      "title": "ここにtitleが入る",
      "introduction": "ここにIntroductionの章が入る",
      "development": "ここにDevelopmentの章が入る",
      "turn": "ここにTurnの章が入る",
      "conclusion": "ここにConclusionの章が入る"
    }
    </OutputExample>

    Output a story in easy Japanese that can be understood by middle school students
    The ratio of kanji to hiragana should be about 1:4. Avoid difficult-to-read kanji characters.
    The story consists of four paragraphs.
    Use JSON format with the keys "introduction", "development", "turn", and "conclusion".
    Output only JSON.
    Please refer to [[OutputExample]] for the output format.

    Write a story with interesting twists and turns as described in the [[storyline]].
    Follow the [[instruction]] to create a story.
    {{Output only JSON.}}
    ''';

  static const String claudeImagePrompt = '''
    <story>
    \$storyText
    </story>

    <positive>
    detailed anime-style illustration, 3d, digital painting, vibrant colors, highly detailed, digital art, clearly
    </positive>

    <negative>
    low quality, cartoon-like, 2d, text, logo, watermark, vague, blurred
    </negative>

    First, figure out who and what each of the main character and other characters in the [[story]] look like.
    Generate positive_prompt_characters and negative_prompt_characters to have stablediffusion generate images of what the main character and the other characters look like.
    Include positive_prompt_characters in the "prompt" of all four paragraphs and negative_prompt_characters in the "negative_prompt" of all four paragraphs.
    In other words, the images are generated so that the protagonist consistently has the same look, the same mood, the same clothes and the same face in all paragraphs. 
    For each of the other characters, the images are generated so that they consistently have the same look, the same mood, the same clothes and the same face in all paragraphs. 
    The same characters should appear consistently across all four paragraphs.

    Please output positive and negative prompts in English for StableDiffusion to generate an image of the scene depicted in [[paragraph]], down to the actions and characters.
    The [[story]] is divided into 4 paragraphs in json format and I would like you to output positive and negative prompts in English for each of them. In other words, I would like you to output 8 prompts in total.
    Positive prompts should include the words in [[positive]] and negative prompts should include the words in [[negative]]. Other words can of course be included as well.
    Please faithfully reproduce the characterization, atmosphere and worldview of the main character. Please include detailed instructions from the name of the main character to describe in detail what you specifically imagine it to look like.
    I want StableDiffusion to generate an image that shows at a glance even the actions of what the main character is doing.

    Please output in JSON format as in the following [[OutputExample]].
    <OutputExample>
    {
      "title": [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
    {
      “introduction”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “development”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “turn”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “conclusion”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ]
    }
    </OutputExample>

    {{Output only JSON.}}

    Output:
    ''';

  static const String claudeImageSystemPrompt = '''
    Please output positive and negative prompts in English for StableDiffusion to generate an image of the scene depicted in [[paragraph]], down to the actions and characters.
    The [[story]] is divided into 4 paragraphs in json format and I would like you to output positive and negative prompts in English for each of them. In other words, I would like you to output 8 prompts in total.
    Positive prompts should include the words in [[positive]] and negative prompts should include the words in [[negative]]. Other words can of course be included as well.
    Please faithfully reproduce the characterization, atmosphere and worldview of the main character. Please include detailed instructions from the name of the main character to describe in detail what you specifically imagine it to look like.
    I want StableDiffusion to generate an image that shows at a glance even the actions of what the main character is doing.
    
    First, figure out who and what each of the main character and other characters in the [[story]] look like.
    Generate positive_prompt_characters and negative_prompt_characters to have stablediffusion generate images of what the main character and the other characters look like.
    Include positive_prompt_characters in the "prompt" of all four paragraphs and negative_prompt_characters in the "negative_prompt" of all four paragraphs.
    In other words, the images are generated so that the protagonist consistently has the same look, the same mood, the same clothes and the same face in all paragraphs. 
    For each of the other characters, the images are generated so that they consistently have the same look, the same mood, the same clothes and the same face in all paragraphs. 
    The same characters should appear consistently across all four paragraphs.

    Please output in JSON format as in the following [[OutputExample]].
    <OutputExample>
    {
      "title": [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
    {
      “introduction”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “development”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “turn”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “conclusion”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ]
    }
    </OutputExample>

   {{Output only JSON.}}
    ''';

  static String generateClaudePromptForExample(String text) {
    return claudeExamplePrompt.replaceAll('\$text', text);
  }

  static String generateClaudePromptForSummary(
      String chatLogs, String summaryMainSettings) {
    return claudeSummaryPrompt
        .replaceAll('\$chatLogs', chatLogs)
        .replaceAll('\$summaryMainSettings', summaryMainSettings);
  }

  static String generateClaudeSystemPromptForSummary(
      String chatLogs, String summaryMainSettings) {
    return claudeSummarySystemPrompt
        .replaceAll('\$chatLogs', chatLogs)
        .replaceAll('\$summaryMainSettings', summaryMainSettings);
  }

  static String generateClaudePromptForTalk(String summary) {
    return claudeTalkPrompt.replaceAll('\$summary', summary);
  }

  static String generateClaudePromptForStory(
      String chatLogs, String storyMainSettings) {
    return claudeStoryPrompt
        .replaceAll('\$chatLogs', chatLogs)
        .replaceAll('\$storyMainSettings', storyMainSettings);
  }

  static String generateClaudePromptForImage(Map<String, dynamic> storyText) {
    return claudeImagePrompt.replaceAll('\$storyText', storyText.toString());
  }
}
