import 'package:get/get.dart';
import 'package:demandium/utils/core_export.dart';
import 'package:lottie/lottie.dart';



class PickMapScreen extends StatefulWidget {
  final bool? fromSignUp;
  final bool? fromAddAddress;
  final bool? canRoute;
  final String? route;
  final bool formCheckout;
  final GoogleMapController? googleMapController;
  final ZoneModel? zone;
  final AddressModel? previousAddress;
  const PickMapScreen({super.key,
    required this.fromSignUp, @required this.fromAddAddress, @required this.canRoute,
    required this.route, this.googleMapController,
    required this.formCheckout, required this.zone,
    this.previousAddress
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  LatLng? _initialPosition;
  LatLng? _centerLatLng;

  Set<Polygon> _polygone = {};
  List<LatLng> zoneLatLongList = [];

  String? pageTitle;
  String? pageSubTitle;

  @override
  void initState() {
    super.initState();
    if(widget.fromAddAddress!) {
      Get.find<LocationController>().setPickData();

    }

    if(widget.zone !=null){
      _centerLatLng = Get.find<ServiceAreaController>().computeCentroid(coordinates: widget.zone!.formattedCoordinates!);
      _initialPosition = LatLng(_centerLatLng!.latitude , _centerLatLng!.longitude);

      widget.zone?.formattedCoordinates?.forEach((element) {
        zoneLatLongList.add(LatLng(element.latitude!, element.longitude!));
      });

      List<Polygon> polygonList = [];

      polygonList.add(
        Polygon(
          polygonId: const PolygonId('1'),
          points: zoneLatLongList,
          strokeWidth: 2,
          strokeColor: Get.theme.colorScheme.primary,
          fillColor: Get.theme.colorScheme.primary.withValues(alpha: .2),
        ),
      );

      _polygone = HashSet<Polygon>.of(polygonList);

    }else{
      _initialPosition = LatLng(
        Get.find<SplashController>().configModel.content?.defaultLocation?.latitude ?? 23.00000,
        Get.find<SplashController>().configModel.content?.defaultLocation?.longitude ?? 90.00000,
      );
    }

    if(widget.route == "search_service"){
      pageTitle = "search_services_near_you".tr;
      pageSubTitle = "${'you_must_select_location_first_to_view'.tr} ${'services'.tr.toLowerCase()}";
    } else if(widget.route == RouteHelper.allServiceScreen){
      pageTitle = "services_near_you".tr;
      pageSubTitle = "${'you_must_select_location_first_to_view'.tr} ${'services'.tr.toLowerCase()}";
    }
    else if(widget.route == RouteHelper.home){
      pageTitle = "home".tr;
      pageSubTitle = "${'you_must_select_location_first_to_view'.tr} ${'home_content'.tr.toLowerCase()}";
    }else if(widget.route == RouteHelper.categories || widget.route ==  RouteHelper.cart || widget.route ==  RouteHelper.offers || widget.route ==  RouteHelper.notification || widget.route == RouteHelper.voucherScreen){
      pageTitle = widget.route?.replaceAll("/", "").tr;
      pageSubTitle = "${'you_must_select_location_first_to_view'.tr} ${widget.route?.replaceAll("/", "").tr.toLowerCase()}";
    }


  }

  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  Widget build(BuildContext context) {
    return CustomPopScopeWidget(
      onPopInvoked: () {
        if (_canExit) {
          if(!GetPlatform.isWeb) {
            exit(0);
          }
        } else {
          customSnackBar('back_press_again_to_exit'.tr, type : ToasterMessageType.info);
          _canExit = true;
          Timer(const Duration(seconds: 2), () {
            _canExit = false;
          });
        }
      },
      child: Scaffold(
        endDrawer: ResponsiveHelper.isDesktop(context) ? const MenuDrawer():null,
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        body: SafeArea(
          child: ResponsiveHelper.isDesktop(context) ? CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: WebShadowWrap(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PageHeaderWidget(
                          title: pageTitle,
                          subtitle: pageSubTitle,
                        ),
                        SizedBox(
                          height: Dimensions.webMaxWidth * 0.5,
                          child: _MapViewWidget(
                            fromAddAddress: widget.fromAddAddress!,
                            initialPosition: _initialPosition,
                            polygons: _polygone,
                            onMapCreated: _onMapCreated,
                            onCameraMove: _onCameraMove,
                            onCameraMoveStarted: _onCameraMoveStarted,
                            onCameraIdle: _onCameraIdle,
                            onSearchTap: _onSearchTap,
                            onLocationTap: _onLocationTap,
                            onPickLocationTap: _onPickLocationTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if(ResponsiveHelper.isDesktop(context)) SliverToBoxAdapter(child: FooterView()),
            ],
          ) : Center(
            child: WebShadowWrap(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeaderWidget(
                    title: pageTitle,
                    subtitle: pageSubTitle,
                  ),
                  Expanded(
                    child: _MapViewWidget(
                      fromAddAddress: widget.fromAddAddress!,
                      initialPosition: _initialPosition,
                      polygons: _polygone,
                      onMapCreated: _onMapCreated,
                      onCameraMove: _onCameraMove,
                      onCameraMoveStarted: _onCameraMoveStarted,
                      onCameraIdle: _onCameraIdle,
                      onSearchTap: _onSearchTap,
                      onLocationTap: _onLocationTap,
                      onPickLocationTap: _onPickLocationTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Callback methods for _MapViewWidget
  void _onMapCreated(GoogleMapController mapController) {
    _mapController = mapController;
    if (!widget.fromAddAddress!) {
      if (widget.zone != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          mapController.animateCamera(CameraUpdate.newLatLngBounds(
            MapHelper.boundsFromLatLngList(zoneLatLongList),
            100.5,
          ));
        });
      } else {
        Get.find<LocationController>().getCurrentLocation(
          false,
          mapController: mapController,
        );
      }
    }
  }

  void _onCameraMove(CameraPosition cameraPosition) {
    _cameraPosition = cameraPosition;
  }

  void _onCameraMoveStarted() {
    Get.find<LocationController>().updateCameraMovingStatus(true);
    Get.find<LocationController>().disableButton();
  }

  void _onCameraIdle() {
    Get.find<LocationController>().updateCameraMovingStatus(false);
    try {
      Get.find<LocationController>().updatePosition(
        _cameraPosition!,
        false,
        formCheckout: widget.formCheckout,
      );
    } catch (e) {
      if (kDebugMode) {
        print('');
      }
    }
  }
  
  void _onSearchTap() {
    if (_mapController != null) {
      Get.dialog(LocationSearchDialog(mapController: _mapController!));
    }
  }

  void _onLocationTap() {
    _checkPermission(() {
      Get.find<LocationController>().getCurrentLocation(
        false,
        deviceCurrentLocation: true,
        mapController: _mapController,
      );
    });
  }

  void _onPickLocationTap() {
    final locationController = Get.find<LocationController>();
    if (locationController.pickPosition.latitude != 0 &&
        locationController.pickAddress.address!.isNotEmpty) {
      if (widget.fromAddAddress!) {
        if (widget.googleMapController != null) {
          widget.googleMapController!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  locationController.pickPosition.latitude,
                  locationController.pickPosition.longitude,
                ),
                zoom: 16,
              ),
            ),
          );
          locationController.setAddAddressData();
        }
        Get.back();
      } else {
        String? firstName;

        if (Get.find<AuthController>().isLoggedIn() &&
            Get.find<UserController>().userInfoModel?.phone != null &&
            Get.find<UserController>().userInfoModel?.fName != null) {
          firstName = "${Get.find<UserController>().userInfoModel?.fName} ";
        }

        AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: 'others',
          address: locationController.pickAddress.address ?? "",
          city: locationController.pickAddress.city ?? "",
          country: locationController.pickAddress.country ?? "",
          house: locationController.pickAddress.house ?? "",
          street: locationController.pickAddress.street ?? "",
          zipCode: locationController.pickAddress.zipCode ?? "",
          addressLabel: AddressLabel.home.name,
          contactPersonNumber: firstName != null
              ? Get.find<UserController>().userInfoModel?.phone ?? ""
              : "",
          contactPersonName: firstName != null
              ? "$firstName${Get.find<UserController>().userInfoModel?.lName ?? ""}"
              : "",
        );

        if (kDebugMode) {
          print("Inside Here ===> Route === > ${widget.route}");
        }
        locationController.saveAddressAndNavigate(
          address,
          widget.fromSignUp!,
          widget.route ?? RouteHelper.getMainRoute('home'),
          widget.canRoute!,
          true,
        );
      }
    } else {
      customSnackBar('pick_an_address'.tr, type: ToasterMessageType.info);
    }
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      customSnackBar('you_have_to_allow'.tr, type: ToasterMessageType.info);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    }else {
      onTap();
    }
  }
}


class AnimatedMapIconExtended extends StatefulWidget {
  const AnimatedMapIconExtended({super.key});

  @override
  State<AnimatedMapIconExtended> createState() => _AnimatedMapIconExtendedState();
}

class _AnimatedMapIconExtendedState extends State<AnimatedMapIconExtended>  {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController){
      return Center(
        child: Stack( alignment: AlignmentDirectional.center, children: [
          Lottie.asset(Images.mapIconExtended , repeat: false, height: Dimensions.pickMapIconSize,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['Red circle Outlines', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['Shape Layer 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['Layer 4', 'Group 1', 'Stroke 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                // Change color of Stroke 1 in Group 2
                ValueDelegate.color(
                  const ['Layer 4', 'Group 2', 'Stroke 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                // Change color of Stroke 1 in Group 3
                ValueDelegate.color(
                  const ['Layer 4', 'Group 3', 'Stroke 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['shadow Outlines', '**'],
                  value: Theme.of(context).colorScheme.primary,
                )
              ],
            ),

          ),
          Padding(
            padding:  const EdgeInsets.only(top: Dimensions.pickMapIconSize * 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min,
              children: List.generate(9, (index){
                return  Icon(Icons.circle, size: index == 8 ? Dimensions.pickMapIconSize * 0.06 : Dimensions.pickMapIconSize * 0.03,
                  color: Theme.of(context).colorScheme.primary,
                );
              }),
            ),
          ),
        ],),
      );
    });
  }
}


class AnimatedMapIconMinimised extends StatefulWidget {
  const AnimatedMapIconMinimised({super.key});

  @override
  State<AnimatedMapIconMinimised> createState() => _AnimatedMapIconMinimisedState();
}

class _AnimatedMapIconMinimisedState extends State<AnimatedMapIconMinimised> with TickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController){
      return Center(
        child: Stack( alignment: AlignmentDirectional.center, children: [
          Lottie.asset(Images.mapIconMinimised , repeat: false, height: Dimensions.pickMapIconSize,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['Red circle Outlines', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['Shape Layer 1', '**'],
                  value: Theme.of(context).colorScheme.primary,
                ),
                ValueDelegate.color(
                  const ['shadow Outlines', '**'],
                  value: Theme.of(context).colorScheme.primary,
                )
              ],
            ),
          ),

          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 0.1),
            duration: const Duration(milliseconds: 400),
            builder: (BuildContext context, double value, Widget? child) {
              return Padding(
                padding:  const EdgeInsets.only(top: Dimensions.pickMapIconSize * 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min,
                  children: List.generate(9, (index){
                    return  Icon(Icons.circle, size: index == 8 ? Dimensions.pickMapIconSize * 0.06 : Dimensions.pickMapIconSize * 0.03,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: value),
                    );
                  }),
                ),
              );
            },
          )
        ],),
      );
    });
  }
}


/// Reusable widget for page header with title and subtitle
class _PageHeaderWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;

  const _PageHeaderWidget({
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? "",
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),
        const SizedBox(height: Dimensions.paddingSizeEight),
        Text(
          subtitle ?? "",
          style: robotoRegular.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );
  }
}

/// Reusable widget for map view with all map functionality
class _MapViewWidget extends StatelessWidget {
  final bool fromAddAddress;
  final LatLng? initialPosition;
  final Set<Polygon> polygons;
  final Function(GoogleMapController) onMapCreated;
  final Function(CameraPosition) onCameraMove;
  final Function() onCameraMoveStarted;
  final Function() onCameraIdle;
  final Function() onSearchTap;
  final Function() onLocationTap;
  final Function() onPickLocationTap;

  const _MapViewWidget({
    required this.fromAddAddress,
    required this.initialPosition,
    required this.polygons,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraMoveStarted,
    required this.onCameraIdle,
    required this.onSearchTap,
    required this.onLocationTap,
    required this.onPickLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      builder: (locationController) {
        return Stack(
          children: [
            // Wrap GoogleMap with AbsorbPointer to prevent scroll propagation on web
            AbsorbPointer(
              absorbing: false,
              child: GestureDetector(
                // This prevents scroll events from propagating to parent widgets
                onVerticalDragStart: (_) {},
                onHorizontalDragStart: (_) {},
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: fromAddAddress
                        ? LatLng(
                      locationController.position.latitude,
                      locationController.position.longitude,
                    )
                        : initialPosition!,
                    zoom: 16,
                  ),
                  minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                  onMapCreated: onMapCreated,
                  onCameraMove: onCameraMove,
                  onCameraMoveStarted: onCameraMoveStarted,
                  onCameraIdle: onCameraIdle,
                  style: Get.isDarkMode
                      ? Get.find<ThemeController>().darkMap
                      : Get.find<ThemeController>().lightMap,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    // This allows the map to capture all gestures
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                  polygons: polygons,
                ),
              ),
            ),

            // Center map icon
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: Dimensions.pickMapIconSize * 0.65,
                ),
                child: locationController.isCameraMoving
                    ? const AnimatedMapIconExtended()
                    : const AnimatedMapIconMinimised(),
              ),
            ),

            // Search bar
            Positioned(
              top: Dimensions.paddingSizeLarge,
              left: Dimensions.paddingSizeSmall,
              right: Dimensions.paddingSizeSmall,
              child: InkWell(
                onTap: onSearchTap,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 25,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withValues(alpha: .6),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Expanded(
                        child: Text(
                          locationController.pickAddress.address ?? "",
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Icon(
                        Icons.search,
                        size: 25,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Location button
            Positioned(
              bottom: 80,
              right: Dimensions.paddingSizeSmall,
              child: FloatingActionButton(
                hoverColor: Colors.transparent,
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                onPressed: onLocationTap,
                child: Icon(
                  Icons.my_location,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),

            // Pick location button
            Positioned(
              bottom: 30.0,
              left: Dimensions.paddingSizeSmall,
              right: Dimensions.paddingSizeSmall,
              child: CustomButton(
                fontSize: Dimensions.fontSizeDefault,
                buttonText: locationController.inZone
                    ? fromAddAddress
                    ? 'pick_address'.tr
                    : 'pick_location'.tr
                    : 'service_not_available_in_this_area'.tr,
                onPressed: (locationController.buttonDisabled ||
                    locationController.loading)
                    ? null
                    : onPickLocationTap,
              ),
            ),
          ],
        );
      },
    );
  }
}