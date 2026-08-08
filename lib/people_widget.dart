import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
// import 'package:tip_calculator/service/shared_data.dart';

class MyPeopleWidget extends StatelessWidget {
  const MyPeopleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(73, 247, 112, 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            children: [
              Text(
                '${context.read<TipData>().translations['people_title']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
            child: TextField(
              controller: context.read<TipData>().peopleController,
              // Head count comes from the people list in item mode.
              enabled: !context.watch<TipData>().isSplitByItems,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                labelText:
                    '${context.read<TipData>().translations['people_input_text']}',
                labelStyle: TextStyle(
                  // fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                filled: false,
              ),
              onChanged: (String newValue) {
                // Empty field falls back to 1 so the per-person maths stays
                // meaningful while the user is retyping.
                context.read<TipData>().setPeople(
                  int.tryParse(newValue) ?? 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
