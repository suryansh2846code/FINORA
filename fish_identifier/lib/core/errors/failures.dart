abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ModelLoadFailure extends Failure {
  const ModelLoadFailure([String message = 'Failed to load model'])
    : super(message);
}

class InferenceFailure extends Failure {
  const InferenceFailure([String message = 'Inference failed'])
    : super(message);
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure([String message = 'Failed to process image'])
    : super(message);
}

class ImagePickFailure extends Failure {
  const ImagePickFailure([String message = 'Failed to pick image'])
    : super(message);
}
