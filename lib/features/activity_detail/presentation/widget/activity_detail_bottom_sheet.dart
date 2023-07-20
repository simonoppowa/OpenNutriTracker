import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ActivityDetailBottomSheet extends StatefulWidget {
  final Function(BuildContext) onAddButtonPressed;
  final PhysicalActivityEntity activityEntity;
  final TextEditingController quantityTextController;
  final ActivityDetailBloc activityDetailBloc;

  const ActivityDetailBottomSheet(
      {Key? key,
      required this.onAddButtonPressed,
      required this.quantityTextController,
      required this.activityEntity,
      required this.activityDetailBloc})
      : super(key: key);

  @override
  State<ActivityDetailBottomSheet> createState() =>
      _ActivityDetailBottomSheetState();
}

class _ActivityDetailBottomSheetState extends State<ActivityDetailBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      elevation: 10,
      onClosing: () {},
      enableDrag: false,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 0.5,
            ),
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.quantityTextController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) => newValue.copyWith(
                                  text: newValue.text.replaceAll(',', '.'),
                                ),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: S.of(context).quantityLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                            child: DropdownButtonFormField(
                          decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: S.of(context).unitLabel),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(child: Text('min'))
                          ],
                          onChanged: (Object? value) {},
                        ))
                      ],
                    ),
                    SizedBox(
                      width: double.infinity, // Make button full width
                      child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onAddButtonPressed(context);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ).copyWith(
                              elevation: ButtonStyleButton.allOrNull(0.0)),
                          icon: const Icon(Icons.add_outlined),
                          label: Text(S.of(context).addLabel)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
