from firebase_functions import https_fn
from anthropic import Anthropic
import os
import traceback

@https_fn.on_request()
def reply(req: https_fn.Request) -> https_fn.Response:
    client = Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
    prompt = """
    <chatlog>
    {user_input}
    </chatlog>

    You are a guide to help children discover the stories they imagine.
    Ask only one element at a time about the setting of a story (e.g., the name of the protagonist, the protagonist's name, the protagonist's place in the story, etc.).
    Omit the preamble and provide only the response.
    Please look at the conversation history so far in [chatlog] and output only the Assistant's next reply.
    Assistant should output a reaction to Human's last statement in [chatlog] and another additional question regarding the setting of the story.
    Please answer in easy-to-understand language, using no more than 20 characters.
    The ratio of kanji to hiragana should be about 1:4.
    Avoid difficult-to-read kanji characters.
    """

    try:
        request_json = req.get_json()
        user_input = request_json['req'] if request_json and 'req' in request_json else ""

        message = client.messages.create(
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": prompt.format(user_input=user_input),
                }
            ],
            model="claude-3-haiku-20240307",
        )
        response = message.content[0].text

        return https_fn.Response(response, status=200)
    except Exception as err:
        err_traceback = traceback.format_exc()
        return https_fn.Response(f"Error: {err}\\nTraceback:\\n{err_traceback}", status=500)
    




<Prompt>
  <Conditions>
    <Title>Create an original story based on a child's imagined setting</Title>
    <ClientCondition>A kindergartner who wants an original story they've imagined to be written</ClientCondition>
    <CreatorCondition>A children's book author aiming to captivate children with a fun story</CreatorCondition>
    <PurposeAndGoals>Write the story the child has imagined</PurposeAndGoals>
  </Conditions>
  <Profile>
    <Age>Kindergarten, 6-10 years old</Age>
  </Profile>
  <ExecutionInstructions>
    Based on the conversation history provided in <ReferenceInformation>, and considering the <Profile>, draw an original story that the kindergartener talking might have imagined. Adjust the number of paragraphs as needed for the story.
  </ExecutionInstructions>
  <OutputFormat>
    Output all in Japanese, using only hiragana. Include only the story's title and content.
    Approximately 500 characters in total.
    Between three to six paragraphs.
    Start the output with "start" followed by a title of up to 20 characters, separate paragraphs with "###", and end with "end".
  </OutputFormat>
  <OutputExample>
    start
    ###
    秘密に包まれた魔法の世界がありました。その国で、若い魔法使いのレナが、不思議な力を持つ伝説の魔法を探して、冒険を始めます。レナは、風を操る杖と、話す猫を仲間に、いろいろな遺跡を探検しました。
    ###
    レナたちが最初に辿り着いたのは、遠い昔になくなったとされる「風の洞窟」でした。ここで、レナは風の精霊と出会い、魔法の呪文を覚えます。二人は、嵐を呼びさます力を使って、危険な景色を乗り越えていきます。
    ###
    そしてレナたちは、氷河の丘にある「氷河の城」へと向かいました。ここでは、時計仕掛けのパズルを解いて、古い魔法の本を見つけることができました。この本には、命を癒す力が含まれており、レナの力もぐんと増えました。
    ###
    レナと仲間たちは、大きな竜が住む「炎の谷」へと辿り着きます。ここで、レナは竜と戦い、かつての戦いで幸せを失った竜の心を解きほぐします。竜は感謝して、レナに最後の魔法「平和のお守り」を渡しました。
    ###
    冒険を終えて、レナは故郷に帰ります。レナは魔法を使って、村の人々に困っている人たちを助け、世界に平和と繁栄をもたらしました。レナの伝説は、世界中の子供たちに夢と希望を語り継ぐことになりました。
    end
  </OutputExample>
  <Style>
    Casual, easy-to-understand language suitable for kindergarteners.
  </Style>
  <ReferenceInformation>
    Conversation history between the kindergartener and you (Claude).
  </ReferenceInformation>
  <MandatoryConditions>
    Output must be entirely in Japanese.
  </MandatoryConditions>
</Prompt>

