import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base use case with parameters
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case without parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Use case with stream return type
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// No parameters class
class NoParams {
  const NoParams();
}
