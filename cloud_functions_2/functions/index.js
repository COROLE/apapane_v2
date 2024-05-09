/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

/**
 * OpenAI APIキーを取得します。
 * @type {string}
 */
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;

/**
 * ChatGPT URL。
 * @type {string}
 */
const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

/**
 * DALL-E URL。
 * @type {string}
 */
const Dall = "https://api.openai.com/v1/images/generations";

/**
 * ChatGPTのプロンプト
 * @type {string}
 */
const prompt =
`
#前提条件:
タイトル:子供が思い描いた話の設定をもとにオリジナルの物語を作る
依頗者条件:自分が思い描いたオリジナルの物語を書いてほしい幼稚園児
制作者条件:子供を魅了する楽しい物語を作る絵本作家
目的と目標:子供が思い描いている物語を書く

#対象プロファイル:
年齢:幼稚園生。6-10歳。

#名詞と動詞と形容詞を使った実行指示:
<対象プロファイル>に対して、<参考情報>にある会話履歴をもとに、その会話をしている幼稚園児が思い描いているであろうオリジナルの物語を、段落に分けて描いてください。
段落数はいくつでも構いません、物語に合わせて変えてください。

#出力形式:
日本語で、すべてひらがなで出力。
物語のタイトルと内容の部分だけ出力。
全部で500字程度。
段落の数は3以上6以下。
<出力例>のように、物語のはじまりに「start」、そのあとに20字以内のタイトル、「###」という半角の記号、段落の区切りで「###」という半角の記号、物語の終わりに「end」を入れる。

#出力例
start
タイトル
###
むかしむかし、まほうとしんぴのせかいがあった。そのなかで、わかいまほうつかいのれなは、でんせつのまほうをさがすたびにでた。れなは、ふるいぶんめいのいせきにかくされたちからをみつけようとした。
###
たびはけけんとしんぴにみちていた。れなは、ふるいせいぶつたちとであい、まほうとちえをまなんだ。ついに、いせきにとうちゃくし、でんせつのまほうのげんせんをはっけんした
###
このちからは、しぜんとちょうわし、いのちをそだてることができるさいきょうのまほうだった。
###
れなはふるさとにかえり、ひとびとにあたらしいきぼうをもたらした。れなはふるいちしきとまほうをつかって、ひとびとのせいかつをゆたかにし、せかいにへいわとはんえいをもたらすことにつとめた。
###
れなのでんせつは、よのなかにとわにかたりつがれるようになった。
###
end

#スタイル
カジュアルで、幼稚園児でもわかる簡単な言葉遣いで。

#参考情報:
幼稚園児とあなた(ChatGPT)とのこれまでの会話履歴。

`;

/**
 * ChatGPTの返答を取得する関数。
 *
 * @param {string} messagelog - AIとユーザーの会話ログ。
 * @return {Promise<string|Error>} - OpenAI APIからの返答またはエラー。
 */
async function story(messagelog) {
  try {
    // プロンプトとメッセージログの結合内容をプリント
    console.log("Sending to ChatGPT:", messagelog + prompt);
    const promptMessagelog = messagelog + prompt;
    const response = await axios.post(
        ANTHROPIC_URL,
        {
          "model": "claude-3-haiku-20240307",
          "messages": [
            {"role": "user", "content": promptMessagelog},
          ],
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${ANTHROPIC_API_KEY}`,
          },
        },
    );
    const ChatgptResponse = response.data.choices[0].message.content;
    // ChatGPTのレスポンス内容をプリント
    console.log("ChatGPT Response:", ChatgptResponse);
    return ChatgptResponse;
  } catch (error) {
    // エラーもプリントする
    console.error("Error:", error);
    return error;
  }
}

/**
 * DALL-Eの返答を取得する関数。
 * @param {string} story - AIによって生成された物語。
 * @return {Promise<string|Error>} - OpenAI APIからの返答またはエラー。
 */
async function image(story) {
  try {
    const response = await axios.post(
        Dall,
        {
          "model": "dall-e-3",
          "prompt": story,
          "n": 1,
          "size": "1024x1792",
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${OPENAI_API_KEY}`,
          },
        },
    );

    return response.data.data[0].url;
  } catch (error) {
    return error;
  }
}

/**
 * HTTPリクエストに対してChatGPTの返答を行います。
 *
 * @param {Object} request - HTTPリクエストオブジェクト。
 * @param {Object} response - HTTPレスポンスオブジェクト。
 * @returns {void}
 */
exports.makeStoryClaude = functions
    .region("asia-northeast1")
    .https.onRequest(async (request, response) => {
      /**
       * AIとユーザーの会話ログ。
       * @type {string}
       */
      // request.query.message
      const messagelog = request.query.message;
      // requestで受け取ったmessagelogをプリント
      console.log("request.query.message:", request.query.message);
      console.log("messagelog:", messagelog);

  try {
  const chatgptStory = await story(messagelog);

  const pattern = /###/g;
  const paragraphs = chatgptStory.split(pattern);

  // Promise.allを使用して、すべての段落に対する画像のリクエストを並列に実行
  const imagePromises = paragraphs.slice(1, paragraphs.length - 1).map(paragraph => 
    paragraph.replace(/\n/g, "") // 段落から改行を削除
  ).map(async (cleanParagraph) => {
    // スタイルの指示を追加
    const styledPrompt = `
    「${cleanParagraph}」という物語のワンシーンを、動作や登場人物まで完全に描写して表現した1枚の画像を出力して。
    この画像を一目みたら、このワンシーンがありありと思い浮かぶような、的確かつ詳細な1枚の画像。
    カラフルでリアルなアニメーションスタイル。
    もしアニメのキャラなど著作権に問題があるなら、問題にならないような、似て非なる画像を出して。
    もし暴力など不適切なコンテンツになりそうであれば、問題にならないような画像を出して。
    幅:高さが9:16の縦向き縦長画像1枚。幅より高さの方が長い。短い幅のところが地面の方向・位置になる。
    画像は複数枚であってはならない。
    文字や文章や吹き出しを1つも入れてはならない。
    `;
    const url = await image(styledPrompt); // スタイル指定を含むプロンプトで画像のURLを取得
    return {story: cleanParagraph, image: url}; // 物語と画像のURLをオブジェクトとして返す
  });

  // すべてのプロミスが解決した後、結果をPictureBookに格納
  const PictureBook = await Promise.all(imagePromises);

  response.send(PictureBook);
} catch (error) {
  response.status(500).send("Internal Server Error" + error);
}


    });
