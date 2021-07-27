import 'dart:ui';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_rest_dashboard/pages/bill/bill.dart';
import 'package:flutter_rest_dashboard/pages/delivery/add.dart';
import 'package:flutter_rest_dashboard/pages/provider/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../function.dart';

import 'detail_billData.dart';

List<DetailBillData> billList = null;
List<DeliverySearch> delList = null;
int sum = 0;

class DetailBill extends StatefulWidget {
  final String bil_id;
  final String bil_regdate;
  final String del_id;
  DetailBill({this.bil_id, this.bil_regdate, this.del_id});
  @override
  _BillState createState() => _BillState();
}

class _BillState extends State<DetailBill> {
  ScrollController myScroll;
  GlobalKey<RefreshIndicatorState> refreshKey;
  int i = 0;
  bool loadingList = false;
  int indexDel = 0;

  void getDatabill(int count, String strSearch) async {
    loadingList = true;
    setState(() {});
    List arr = await getData(count, "bill/readdetail_bill_d.php", strSearch,
        "bil_id=${widget.bil_id}&");
    for (int i = 0; i < arr.length; i++) {
      billList.add(new DetailBillData(
        det_id: arr[i]["det_id"],
        foo_id: arr[i]["foo_id"],
        foo_name: arr[i]["foo_name"],
        foo_image: arr[i]["foo_image"],
        det_note: arr[i]["det_note"],
        det_price: arr[i]["det_price"],
        det_qty: arr[i]["det_qty"],
      ));
      sum += int.parse(arr[i]["det_price"]) * int.parse(arr[i]["det_qty"]);
    }
    loadingList = false;
    setState(() {});
  }

  void getDataDelivery() async {
    loadingList = true;
    setState(() {});
    List arr = await getDataDropDown("bill/get_delivery.php", "");
    delList = new List<DeliverySearch>();
    delList.add(new DeliverySearch(
      del_id: "0",
      del_name: "حدد الدليفري المطلوب",
    ));
    for (int i = 0; i < arr.length; i++) {
      if (arr[i]["del_id"] == widget.del_id) {
        indexDel = i + 1;
      }
      delList.add(new DeliverySearch(
        del_id: arr[i]["del_id"],
        del_name: arr[i]["del_name"],
      ));
    }
    loadingList = false;
    setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    myScroll.dispose();
    billList.clear();
    delList.clear();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDataDelivery();
    sum = 0;
    _appBarTitle =
        new Text("تفاصيل الطلبية", style: TextStyle(color: Colors.black));
    billList = new List<DetailBillData>();
    myScroll = new ScrollController();
    refreshKey = GlobalKey<RefreshIndicatorState>();
    getDatabill(0, "");

    myScroll.addListener(() {
      if (myScroll.position.pixels == myScroll.position.maxScrollExtent) {
        i += 20;
        getDatabill(i, "");
        print("scroll");
      }
    });
  }

  Icon _searchIcon = new Icon(
    Icons.search,
    color: Colors.black,
  );
  Widget _appBarTitle;

  Widget _customDropDownDelivery(
      BuildContext context, DeliverySearch item, String itemDesignation) {
    if (item == null) {
      return Container();
    }
    return Container(
      child: ListTile(
        contentPadding: EdgeInsets.all(0),
        title: Text(item.del_name),
      ),
    );
  }

  addDeliveryToBill(String del_id, String bil_id) async {
    if (del_id != "0") {
      Map arr = {
        "bil_id": bil_id,
        "del_id": del_id,
      };
      bool res = await SaveData(
          arr, "bill/add_delivery_bill.php", context, () => Bill(), "update");
    }
  }

  @override
  Widget build(BuildContext context) {
    var myProvider = Provider.of<LoadingControl>(context);
    return Container(
      child: Scaffold(
          appBar: AppBar(
            title: _appBarTitle,
            backgroundColor: Colors.white,
            leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              Container(
                height: 250,
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("رقم الفاتورة" + " " + widget.bil_id,
                        style: TextStyle(fontFamily: "arial", fontSize: 16)),
                    Text("تاريخ الفاتورة" + " " + widget.bil_regdate,
                        style: TextStyle(fontFamily: "arial", fontSize: 16)),
                    Text("اجمالي الفاتورة" + " " + sum.toString(),
                        style: TextStyle(fontFamily: "arial", fontSize: 16)),
                    Container(
                      child: Text("الدليفري"),
                    ),
                    delList == null || delList.length == 0
                        ? Text("")
                        : DropdownSearch<DeliverySearch>(
                            searchBoxController:
                                TextEditingController(text: ""),
                            mode: Mode.BOTTOM_SHEET,
                            showClearButton: true,
                            showSearchBox: true,
                            selectedItem: delList[indexDel],
                            items: delList,
                            itemAsString: (DeliverySearch del) => del.del_name,
                            onChanged: (DeliverySearch data) {
                              if (data != null) {
                                print(data.del_id);
                                addDeliveryToBill(
                                  data.del_id,
                                  widget.bil_id,
                                );
                              }
                            },
                            dropdownBuilder: _customDropDownDelivery,
                          )
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height - 140,
                child: RefreshIndicator(
                  onRefresh: () async {
                    i = 0;
                    billList.clear();
                    await getDatabill(0, "");
                  },
                  key: refreshKey,
                  child: ListView.builder(
                    controller: myScroll,
                    itemCount: billList.length,
                    itemBuilder: (context, index) {
                      return SingleDetailBill(
                        bil_index: index,
                        DetailBill: billList[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

class SingleDetailBill extends StatelessWidget {
  int bil_index;
  DetailBillData DetailBill;
  SingleDetailBill({this.bil_index, this.DetailBill});

  bool isloadingFav = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Card(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  new Text(
                      "الاجمالي :" +
                          (int.parse(DetailBill.det_qty) *
                                  int.parse(DetailBill.det_price))
                              .toString(),
                      style: TextStyle(fontFamily: "arial", fontSize: 16)),
                  new Text("      "),
                  new Text("السعر : " + DetailBill.det_price,
                      style: TextStyle(
                          fontFamily: "arial",
                          color: Colors.red,
                          fontSize: 16)),
                  new Text(" "),
                  new Text("الكمية :" + DetailBill.det_qty,
                      style: TextStyle(
                          fontFamily: "arial",
                          color: Colors.red,
                          fontSize: 16)),
                  new Text(" "),
                ],
              ),
              new Text(
                DetailBill.foo_name,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliverySearch {
  String del_id;
  String del_name;
  DeliverySearch({this.del_id, this.del_name});
}
