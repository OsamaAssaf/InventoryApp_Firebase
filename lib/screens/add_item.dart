import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventoryapp_firebase/database/database.dart';
import 'package:inventoryapp_firebase/modules/item.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class AddItem extends StatefulWidget {
  AddItem(
      {Key? key,
      this.id,
      this.name,
      this.description,
      this.category,
      this.quantity,
      this.price,
      this.image,
      required this.edit})
      : super(key: key);

  String? id;

  String? name;

  String? description;

  String? category;

  int? quantity;

  double? price;

  String? image;

  final bool edit;

  @override
  _AddItemState createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  List<String> categoryList = ['Electrical', 'Food', 'Other'];

  @override
  Widget build(BuildContext context) {
    widget.category ??= 'Electrical';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        actions: [
          widget.edit
              ? IconButton(
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Delete this Item.'),
                              content: const Text('Are you sure?'),
                              actions: [
                                TextButton(
                                    onPressed: () async {
                                      await context
                                          .read<Database>()
                                          .deleteItem(widget.id!);
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Ok')),
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel')),
                              ],
                            ));
                  },
                  icon: const Icon(Icons.delete),
                )
              : Container(
                  height: 0.0,
                ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 8.0,
                  ),
                  inputOne('Name'),
                  inputOne('Description'),
                  inputTow(),
                  inputThree('Quantity'),
                  inputThree('Price'),
                  const Divider(
                    thickness: 3,
                  ),
                  inputFour(),
                  buildElevatedButton(context)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton buildElevatedButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          minimumSize: Size(MediaQuery.of(context).size.width * 0.40, 50),
          side: const BorderSide(width: 2, color: Colors.grey),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(20)),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          if (widget.image == null) {
            Fluttertoast.showToast(
                msg: 'Please add image',
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black54,
                textColor: Colors.white,
                fontSize: 16.0);
            return;
          }
          _formKey.currentState!.save();
          if (widget.edit) {
            await context.read<Database>().updateData(
                  Item(
                      id: widget.id,
                      name: widget.name,
                      description: widget.description,
                      category: widget.category,
                      quantity: widget.quantity,
                      price: widget.price,
                      imageUrl: widget.image),
                );
          } else {
            try {
              await context.read<Database>().addItem(
                    Item(
                        name: widget.name,
                        description: widget.description,
                        category: widget.category,
                        quantity: widget.quantity,
                        price: widget.price,
                        imageUrl: widget.image),
                  );
            } catch (e) {
              showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                        content: Text('Failed to add item, try again!'),
                      ));
            }
          }
          Navigator.of(context).pop();
        }
      },
      child: const Text('Add Item'),
    );
  }

  inputOne(String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: widget.edit
              ? type == 'Name'
                  ? widget.name
                  : widget.description
              : '',
          decoration: InputDecoration(
            label: Text(
              type,
              style: Theme.of(context).textTheme.subtitle1,
            ),
            border: OutlineInputBorder(
                borderSide: const BorderSide(width: 2),
                borderRadius: BorderRadius.circular(15)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a ${type.toLowerCase()}';
            }
            return null;
          },
          onSaved: (newValue) {
            switch (type) {
              case 'Name':
                widget.name = newValue!;
                break;
              case 'Description':
                widget.description = newValue!;
            }
          },
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  inputTow() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(width: 1, color: Colors.black38)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Category', style: Theme.of(context).textTheme.subtitle1),
                const SizedBox(
                  width: 10.0,
                ),
                DropdownButton(
                  iconDisabledColor: Colors.white,
                  iconEnabledColor: Colors.white,
                  value: widget.category,
                  items: categoryList
                      .map((value) => DropdownMenuItem<String>(
                            child: Text(
                              value,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                            value: value,
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      widget.category = newValue.toString();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  inputThree(String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150.0,
          child: TextFormField(
            initialValue: widget.edit
                ? type == 'Quantity'
                    ? widget.quantity.toString()
                    : widget.price.toString()
                : '',
            decoration: InputDecoration(
              label: Text(
                type,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              border: OutlineInputBorder(
                  borderSide: const BorderSide(width: 2),
                  borderRadius: BorderRadius.circular(15)),
              suffix: type == 'Price'
                  ? const Text('\$')
                  : Container(
                      width: 0,
                    ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '';
              } else if (double.tryParse(value) == null) {
                return 'not correct value';
              }
              return null;
            },
            onSaved: (newValue) {
              switch (type) {
                case 'Quantity':
                  widget.quantity = int.parse(newValue!);
                  break;
                case 'Price':
                  widget.price = double.parse(newValue!);
              }
            },
          ),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  inputFour() {
    return Column(
      children: [
        const SizedBox(
          height: 10.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(35.0),
              child: Material(
                borderRadius: BorderRadius.circular(35.0),
                elevation: 3,
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  radius: 35.0,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              onTap: () async {
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.camera);
                if (photo == null) {
                  return;
                }
                setState(() {
                  widget.image =
                      base64Encode(File(photo.path).readAsBytesSync());
                });
              },
            ),
            InkWell(
              borderRadius: BorderRadius.circular(35.0),
              child: Material(
                borderRadius: BorderRadius.circular(35.0),
                elevation: 3,
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  radius: 35.0,
                  child: const Icon(
                    Icons.photo_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              onTap: () async {
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (photo == null) {
                  return;
                }

                setState(() {
                  widget.image =
                      base64Encode(File(photo.path).readAsBytesSync());
                });
              },
            ),
          ],
        ),
        const SizedBox(
          height: 10.0,
        ),
        widget.image != null
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Image.memory(
                  base64Decode(widget.image!),
                  fit: BoxFit.fill,
                ),
              )
            : Container(
                height: 0.0,
              ),
        const SizedBox(
          height: 10.0,
        ),
      ],
    );
  }
}
