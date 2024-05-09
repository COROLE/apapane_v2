import 'package:apapane/model/model_class/exception_class.dart';

import 'package:flutter/cupertino.dart';
import 'package:apapane/details/bottom_nav_bar_no.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Fn = Function({required DateTime date});
typedef DateHandler = void Function(DateTime date);

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? _errorMessage;
  String? _errorMessageNew; // 初期値はnull
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    isChanged = false;
  }

  Future<void> showCupertinoDatePicker({
    required double sheetHeight,
    required double itemHeight,
    required double textSize,
    required DateHandler handler,
    required BuildContext context,
  }) async {
    final int minYear = DateTime.now().year - 115; // 115歳まで登録できる
    final int maxYear = DateTime.now().year - 2;

    // 選択された日付が制約内にあるように初期値を設定
    final initialDate = selectedDate.isBefore(DateTime(minYear, 1, 1))
        ? DateTime(minYear, 1, 1)
        : selectedDate.isAfter(DateTime(maxYear, 12, 31))
            ? DateTime(maxYear, 12, 31)
            : selectedDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: sheetHeight,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: TextButton(
                    child: Text(
                      '閉じる',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: textSize,
                      ),
                    ),
                    onPressed: () {
                      handler(selectedDate);
                      setState(() {
                        isChanged = true;
                      });
                      Navigator.of(context).pop();
                    }),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumYear: minYear,
                  maximumYear: maxYear,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      selectedDate = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 新規登録時にデータを保存
  _createAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', _userNameController.text);
    prefs.setString('password', _passwordController.text);
    prefs.setString('mail', _mailController.text);
    prefs.setString('birthday', selectedDate.toString());
  }

  // ログイン処理
  _login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedMail = prefs.getString('mail') ?? "";
    String savedPassword = prefs.getString('password') ?? "";
    if (_passwordController.text.isEmpty || _mailController.text.isEmpty) {
      setState(() {
        _errorMessage = '全ての項目を正しい形式で入力してください';
      });
    } else if (!emailPattern.hasMatch(_mailController.text)) {
      setState(() {
        _errorMessage = '正しいメールアドレスを入力してください';
      });
    } else if (_mailController.text == savedMail &&
        _passwordController.text == savedPassword) {
      // ログイン成功
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavBar(),
        ),
      );
    } else {
      // ログイン失敗
      throw LoginException("ログインに失敗しました。メールアドレスまたはパスワードが正しくありません。");
    }
  }

  final emailPattern = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(
                text: 'しんきとうろく',
              ),
              Tab(
                text: 'ログイン',
              )
            ],
            unselectedLabelColor: Colors.grey,
            labelColor: Colors.pink,
            indicatorColor: Colors.pink,
          ),
        ),
        body: TabBarView(children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                const Text(
                  "*おうちのひとにみせてね*",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 6, 6),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25.0),
                  child: Text(
                    "新規登録",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 50, left: 50, right: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ひょうじするなまえ"),
                      TextField(
                        controller: _userNameController,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.pink,
                            ),
                          ),
                          hintText: '入力してください',
                          icon: Icon(Icons.person),
                          iconColor: Colors.pink,
                        ),
                        autofocus: true,
                      ),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      const Text("メールアドレス"),
                      TextField(
                        controller: _mailController,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.pink,
                            ),
                          ),
                          hintText: '入力してください',
                          icon: Icon(Icons.mail_outline_rounded),
                          iconColor: Colors.pink,
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      const Text("　　　パスワード"),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.pink,
                            ),
                          ),
                          hintText: '入力してください',
                          icon: Icon(Icons.lock_outline_rounded),
                          iconColor: Colors.pink,
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 40),
                        child: Text('お誕生日'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: TextButton(
                          onPressed: () {
                            showCupertinoDatePicker(
                              sheetHeight: screenHeight * 0.4,
                              itemHeight: 35,
                              textSize: 20,
                              handler: (date) {
                                setState(() {
                                  selectedDate = date;
                                });
                              },
                              context: context,
                            );
                          },
                          child: Text(
                            '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                            style: const TextStyle(
                                color: Colors.pink,
                                fontSize: 25,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.7,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: const BorderSide(
                        color: Color.fromARGB(253, 252, 42, 0),
                      ),
                    ),
                    onPressed: () {
                      // エラーメッセージが表示されている場合はクリア
                      setState(() {
                        _errorMessageNew = null;
                      });

                      if (_userNameController.text.isEmpty ||
                          _passwordController.text.isEmpty ||
                          _mailController.text.isEmpty ||
                          isChanged == false) {
                        setState(() {
                          _errorMessageNew = '全ての項目を正しい形式で入力してください';
                        });
                      } else if (!emailPattern.hasMatch(_mailController.text)) {
                        setState(() {
                          _errorMessageNew = '正しいメールアドレスを入力してください';
                        });
                      } else {
                        // メールアドレスの形式も正しい場合の処理
                        _createAccount();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BottomNavBar(),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "とうろく",
                      style: TextStyle(
                        color: Color.fromARGB(253, 252, 42, 0),
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),

                // エラーメッセージを表示するTextウィジェット
                if (_errorMessageNew != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SizedBox(
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.2,
                      child: Text(
                        _errorMessageNew!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                const Text(
                  "*おうちのひとにみせてね*",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 6, 6),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25.0),
                  child: Text(
                    "ログイン",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 50, left: 50, right: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("メールアドレス"),
                      TextField(
                        controller: _mailController,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.pink,
                            ),
                          ),
                          hintText: '入力してください',
                          icon: Icon(Icons.mail_outline_rounded),
                          iconColor: Colors.pink,
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      const Text("　　　パスワード"),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.pink,
                            ),
                          ),
                          hintText: '入力してください',
                          icon: Icon(Icons.lock_outline_rounded),
                          iconColor: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.7,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: const BorderSide(
                        color: Color.fromARGB(253, 252, 42, 0),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        // ログイン処理を呼び出す
                        await _login();
                      } catch (e) {
                        if (e is LoginException) {
                          // ログインエラーが発生した場合、エラーメッセージを表示
                          setState(() {
                            // エラーメッセージを表示するためにStateを更新
                            _errorMessage = e.message;
                          });
                          // ここでエラーメッセージをユーザーに表示するなどの処理を追加できます
                        }
                      }
                    },
                    child: const Text(
                      "ログイン",
                      style: TextStyle(
                        color: Color.fromARGB(253, 252, 42, 0),
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
                // エラーメッセージを表示するTextウィジェット
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SizedBox(
                      width: screenWidth * 0.7,
                      height: screenHeight * 0.2,
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                SizedBox(
                  height: screenHeight * 0.15,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
