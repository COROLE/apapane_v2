//flutter
import 'package:flutter/material.dart';
//packages
import 'package:intl/intl.dart' as intl;
//constants
import 'package:apapane/constants/strings.dart';
//models
import 'package:apapane/model/chat_model.dart';

class ChatUi extends StatelessWidget {
  const ChatUi({Key? key, required this.chatModel, required this.screenHeight})
      : super(key: key);

  final ChatModel chatModel;
  final double screenHeight;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: chatModel.scrollController,
        physics: const RangeMaintainingScrollPhysics(),
        shrinkWrap: true,
        reverse: false,
        itemCount: chatModel.messagesList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              top: 15,
              left: 10,
              right: 10,
              bottom: index == 0 ? screenHeight * 0.06 : 0,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: chatModel.messagesList[index].isMe
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  children: [
                    !chatModel.messagesList[index].isMe
                        ? const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color.fromARGB(255, 254, 236, 236),
                            child: CircleAvatar(
                              backgroundImage: AssetImage(apapaneImage),
                              radius: 25,
                              backgroundColor: Colors.white,
                            ),
                          )
                        : Container(),
                    const SizedBox(width: 5),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: !chatModel.messagesList[index].isMe
                            ? Border.all(
                                width: 1,
                                color: const Color.fromARGB(255, 105, 105, 105),
                              )
                            : const Border(),
                        color: chatModel.messagesList[index].isMe
                            ? const Color.fromARGB(255, 106, 252, 53)
                            : Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Text(
                        chatModel.messagesList[index].message,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(intl.DateFormat('HH:mm')
                        .format(chatModel.messagesList[index].sendTime)),
                  ],
                ),
                !chatModel.messagesList[index].isMe
                    ? SizedBox(
                        height: screenHeight * 0.02,
                      )
                    : const SizedBox()
              ],
            ),
          );
        },
      ),
    );
  }
}
