import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/tip_data.dart';
// import 'package:tip_calculator/service/shared_data.dart';

class MyAmountWidget extends StatelessWidget {
  const MyAmountWidget({super.key});

  //final Function(double) onUpdate;
  //const MyAmountWidget({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(45, 174, 253, 0.5),
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
                '${context.read<TipData>().translations['amount_title']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
            child: TextField(
              controller: context.read<TipData>().amountController,
              // In item mode the bill is the sum of everyone's items, so a
              // typed amount would be silently ignored.
              enabled: !context.watch<TipData>().isSplitByItems,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9]+[,|.]{0,1}[0-9]*'),
                ),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                    text: newValue.text.replaceAll('.', ','),
                  ),
                ),
              ],
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                labelText:
                    '${context.read<TipData>().translations['amount_input_text']}',
                labelStyle: TextStyle(
                  // fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                filled: false,
              ),
              onChanged: (newAmount) {
                // Clearing the field, or a lone separator, is not a number --
                // double.parse would throw on every keystroke.
                final parsed = double.tryParse(
                  newAmount.replaceAll(",", "."),
                );
                context.read<TipData>().setAmount(parsed ?? 0.00);
              },
            ),
          ),
        ],
      ),
    );
  }
}
