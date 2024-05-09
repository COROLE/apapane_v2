import os
import traceback
import json
import requests
import concurrent.futures
from google.cloud import functions
from anthropic import Anthropic
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

def get_claude_response(message_log):
    prompt = """
    <chatlog>
        {user_input}
    </chatlog>

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
    """
    try:
        client = Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
        message = client.messages.create(
            messages=[
                {
                    "role": "user",
                    "content": prompt.format(user_input=message_log),
                }
            ],
            model="claude-3-haiku-20240307",
            max_tokens=1000  # 生成するトークンの最大数を指定
        )
        response = message.content[0].text
        return response
    except Exception as err:
        err_traceback = traceback.format_exc()
        return Exception(f"Error: {str(err)}\nTraceback:\n{err_traceback}")

def generate_image(prompt, headers):
    data = {
        "model": "dall-e-3",
        "prompt": prompt.strip(),
        "n": 1,
        "size": "1024x1792"
    }
    try:
        response = requests.post("https://api.openai.com/v1/images/generations", json=data, headers=headers)
        response.raise_for_status()
        return response.json()['data'][0]['url']
    except requests.RequestException as e:
        print(f"Request failed: {e}, {prompt}")
        return None

def generate_images(story):
    api_key = os.environ.get("OPENAI_API_KEY")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    prompts = story.split("###")[1:-1]
    images = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        future_to_image = {executor.submit(generate_image, prompt, headers): prompt for prompt in prompts}
        for future in concurrent.futures.as_completed(future_to_image):
            prompt = future_to_image[future]
            try:
                image_url = future.result()
                if image_url:
                    images.append(image_url)
            except Exception as exc:
                print(f"{prompt} generated an exception: {exc}")
    return images

def storymaker(request):
    try:
        request_json = request.get_json(silent=True)
        if request.args and 'message' in request.args:
            message_log = request.args['message']
        elif request_json and 'message' in request_json:
            message_log = request_json['message']
        else:
            return json.dumps({"error": "No message provided"}), 400

        claude_story = get_claude_response(message_log)
        if isinstance(claude_story, Exception):
            error_message = f"Failed to get response: {str(claude_story)}"
            print(error_message)
            return json.dumps({"error": error_message}), 500

        images = generate_images(claude_story)
        if isinstance(images, Exception):
            error_message = f"Failed to generate images: {str(images)}"
            print(error_message)
            return json.dumps({"error": error_message}), 500

        # 画像URLとストーリーの各パートを組み合わせて返す
        story_parts = claude_story.split("###")[1:-1]  # ストーリーを分割
        results = []
        for i, image_url in enumerate(images):
            if i < len(story_parts):  # 画像の数とストーリーパートの数が一致するように
                results.append({"story": story_parts[i], "image": image_url})
            else:
                break  # 画像の数より多いストーリーパートがあれば無視

        return json.dumps(results), 200

    except Exception as e:
        traceback_str = traceback.format_exc()
        print(f"Unhandled error: {str(e)}\n{traceback_str}")
        return json.dumps({"error": str(e), "traceback": traceback_str}), 500


# Cloud Functionをデプロイするための記述
if __name__ == "__main__":
    functions.http("storymaker")(storymaker)
