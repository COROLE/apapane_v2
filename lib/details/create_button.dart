//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/strings.dart';

class CreateButton extends StatelessWidget {
  const CreateButton({
    Key? key,
    required this.isValidCreate,
    required this.width,
    required this.height,
    required this.onPressed,
    this.judgeMode = false,
  }) : super(key: key);
  final bool isValidCreate;
  final double width;
  final double height;
  final bool judgeMode;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: ElevatedButton(
          style: ButtonStyle(
            shadowColor: isValidCreate
                ? MaterialStateProperty.all(Colors.grey.withOpacity(0.5))
                : null, // シャドウの色と透明度
            elevation: isValidCreate ? MaterialStateProperty.all(8) : null,
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            padding: MaterialStateProperty.all(EdgeInsets.zero),
          ),
          onPressed: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: isValidCreate
                  ? const Color.fromARGB(255, 234, 67, 53)
                  : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: width, minHeight: height),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    createText,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(
                    width: 3,
                  ),
                  Icon(
                    Icons.create,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
