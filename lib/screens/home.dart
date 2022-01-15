import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventoryapp_firebase/controllers/auth.dart';
import 'package:inventoryapp_firebase/controllers/theme_controller.dart';
import 'package:inventoryapp_firebase/database/database.dart';
import 'package:inventoryapp_firebase/modules/item.dart';
import 'package:provider/provider.dart';

import 'add_item.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<String> categoryList = ['All', 'Electrical', 'Food', 'Other'];

  String category = 'All';

  String? currency() {
    Locale locale = Localizations.localeOf(context);
    NumberFormat format =
        NumberFormat.simpleCurrency(locale: locale.toString());
    return format.currencyName;
  }

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<Database>().getItems().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    bool? isDark = context.watch<ThemeController>().isDark ?? false;

    List<Item> itemList = context.watch<Database>().itemList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          Row(
            children: [
              const Text('Category'),
              const SizedBox(
                width: 10.0,
              ),
              DropdownButton(
                iconDisabledColor: Colors.white,
                iconEnabledColor: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                dropdownColor: Colors.grey,
                value: category,
                items: categoryList
                    .map((value) => DropdownMenuItem<String>(
                          child: Text(value,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                              )),
                          value: value,
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    category = newValue.toString();
                  });
                  if (category == 'All') {
                    context.read<Database>().getItems();
                  } else {
                    context.read<Database>().getItems(category);
                  }
                },
              ),
              const SizedBox(
                width: 10.0,
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : itemList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_rounded,
                        size: width / 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Text(
                        "Empty",
                        style: Theme.of(context).textTheme.headline1,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async =>
                      await context.read<Database>().getItems(),
                  child: ListView.builder(
                    itemCount: itemList.length,
                    itemBuilder: (BuildContext context, int index) {
                      Item item = itemList[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AddItem(
                                    id: item.id,
                                    name: item.name,
                                    description: item.description,
                                    category: item.category,
                                    quantity: item.quantity,
                                    price: item.price,
                                    image: item.imageUrl,
                                    edit: true,
                                  )));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            color: Colors.grey,
                            elevation: 5.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (_) {
                                          return AlertDialog(
                                            content: InteractiveViewer(
                                              panEnabled: false,
                                              maxScale: 5.0,
                                              child: Image.memory(
                                                base64Decode(item.imageUrl!),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          );
                                        });
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: height * 0.15,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(25.0),
                                          topRight: Radius.circular(25.0)),
                                      child: Image.memory(
                                        base64Decode(item.imageUrl!),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    item.name!,
                                    style:
                                        Theme.of(context).textTheme.headline1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text('quantity: ${item.quantity!}'),
                                      Text(
                                          'price: ${item.price!} ${currency()}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Inventory App',
                style: Theme.of(context).textTheme.headline2,
              ),
            ),
            ListTile(
              title: Text(
                'Delete All',
                style: Theme.of(context).textTheme.headline3,
              ),
              trailing: const Icon(Icons.delete_outline_outlined,
                  color: Colors.black38),
              onTap: () {
                if (itemList.isEmpty) {
                  return;
                }
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                          title: const Text('Delete all item.'),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  await context
                                      .read<Database>()
                                      .deleteAllItem();
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
            ),
            ListTile(
              title: Text(
                'Theme',
                style: Theme.of(context).textTheme.headline3,
              ),
              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'light',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                    Switch(
                      value: isDark,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      inactiveThumbColor: Colors.grey[400],
                      onChanged: (val) {
                        setState(() {
                          isDark = val;
                        });
                        context.read<ThemeController>().setTheme(val);
                        context.read<ThemeController>().getTheme();
                      },
                    ),
                    Text(
                      'dark',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: Text(
                'Log Out',
                style: Theme.of(context).textTheme.headline3,
              ),
              trailing: const Icon(Icons.logout, color: Colors.black38),
              onTap: () {
                context.read<Database>().clearItemList();
                context.read<Auth>().logout();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddItem(
                    edit: false,
                  )));
        },
      ),
    );
  }
}
