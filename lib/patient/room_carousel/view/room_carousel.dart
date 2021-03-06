import 'package:criticalcare/patient/patient.dart';
import 'package:criticalcare/patient/realtime_device/cubit/realtime_device_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hospital_repository/hospital_repository.dart';
import 'package:patient_repository/patient_repository.dart';

class RoomCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RoomCarouselCubit(
        context.repository<HospitalRepository>(),
        context.repository<PatientRepository>(),
      )..getRooms('hospital-0'),
      child: BlocListener<RoomCarouselCubit, RoomCarouselState>(
        // listening only for when the selected room has changed.
        // if new rooms but still selecting the same room.
        listenWhen: (previous, current) {
          // room hasn't changed
          return previous.selectedRoom != current.selectedRoom;
        },
        listener: (context, state) {
          context
              .bloc<PatientProfileCubit>()
              .getPatientProfile(state.selectedRoom.patientId);

          // is this the right way to do this?
          context
              .bloc<PatientRecordsCubit>()
              .getPatientRecords(state.selectedRoom.patientId);

          // is this the right way to do this?
          context
              .bloc<RealtimeDeviceCubit>()
              .getRealtimeDevice(state.selectedRoom.patientId);
        },
        child: RoomCarouselView(),
      ),
    );
  }
}

class RoomCarouselView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCarouselCubit, RoomCarouselState>(
      builder: (context, state) {
        switch (state.status) {
          case RoomCarouselStatus.loading:
            return _RoomCarouselLoadingView();
          case RoomCarouselStatus.success:
            return _RoomCarouselSuccessView(
              rooms: state.rooms,
              selectedRoom: state.selectedRoom,
            );
          case RoomCarouselStatus.failure:
          default:
            return _RoomCarouselFailureView();
        }
      },
    );
  }
}

class _RoomCarouselLoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _RoomCarouselSuccessView extends StatelessWidget {
  const _RoomCarouselSuccessView({
    Key key,
    @required this.rooms,
    @required this.selectedRoom,
  }) : super(key: key);

  final List<Room> rooms;
  final Room selectedRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 24,
          color: Theme.of(context).highlightColor,
          child: Center(
            child: RichText(
              text: TextSpan(
                text: 'Emergency Care Unit - West Wing',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rooms.map(
              (room) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    width: 60,
                    height: 60,
                    child: _RoomView(
                      room: room,
                      // handle the changing of rooms in the cubit
                      onTap: () {
                        context.bloc<RoomCarouselCubit>().changeRoom(room.id);
                        print(room.status);
                      },
                      selectedRoom: selectedRoom,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }
}

class _RoomView extends StatelessWidget {
  const _RoomView({Key key, @required this.room, this.onTap, this.selectedRoom})
      : super(key: key);

  final Room room;
  final VoidCallback onTap;
  final Room selectedRoom;

  @override
  Widget build(BuildContext context) {
    final isSelected = room.id == selectedRoom.id;
    final status = room.status;

    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).toggleableActiveColor
                : const Color(0xFFCCCCCC),
            border: Border.all(
              color: Theme.of(context)
                  .backgroundColor, //                   <--- border color
              width: 1.0,
            ),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //decoration around the circle avatar for status
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: status.toColor,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      position: DecorationPosition.foreground,
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(room.imageUrl),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: room.name,
                            style: isSelected
                                ? Theme.of(context).textTheme.bodyText1
                                : Theme.of(context).textTheme.bodyText2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCarouselFailureView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Something went wrong!'));
  }
}

extension on RoomStatus {
  Color get toColor {
    switch (this) {
      case RoomStatus.green:
        return Colors.green;
      case RoomStatus.yellow:
        return Colors.yellow;
      case RoomStatus.red:
        return Colors.red;
      case RoomStatus.none:
      default:
        return Colors.black;
    }
  }
}
