import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/services/playback_looper.dart';

void main() {
  group('PlaybackLooper — §3.5 YouTube loop algorithm', () {
    test('continues playing before reaching end', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluate(positionSeconds: 20, completedCount: 0);
      expect(d.action, PlaybackLoopAction.continuePlaying);
    });

    test('seeks back when reaching end without count-in', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluate(positionSeconds: 30, completedCount: 1);
      expect(d.action, PlaybackLoopAction.seekBack);
      expect(d.seekToSeconds, 10);
      expect(d.nextCompletedCount, 2);
    });

    test('triggers count-in before seek-back when enabled', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: true,
      );
      final d = looper.evaluate(positionSeconds: 30, completedCount: 1);
      expect(d.action, PlaybackLoopAction.countInThenSeekBack);
      expect(d.nextCompletedCount, 2);
    });

    test('completes target on final loop', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 3,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluate(positionSeconds: 30, completedCount: 2);
      expect(d.action, PlaybackLoopAction.completeTarget);
      expect(d.nextCompletedCount, 3);
    });

    test('loop disabled → always continue', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: false,
        countInEnabled: false,
      );
      final d = looper.evaluate(positionSeconds: 31, completedCount: 0);
      expect(d.action, PlaybackLoopAction.continuePlaying);
    });

    test('first play with count-in triggers countInThenPlay', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: true,
      );
      final d = looper.evaluateFirstPlay();
      expect(d.action, PlaybackLoopAction.countInThenPlay);
      expect(d.seekToSeconds, 10);
    });

    test('first play without count-in seeks to start immediately', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluateFirstPlay();
      expect(d.action, PlaybackLoopAction.seekBack);
      expect(d.seekToSeconds, 10);
    });

    // §3.5 #509 — ad-playing flag must protect the counter.
    test('ad playing → continuePlaying even at loop boundary', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluate(
        positionSeconds: 30,
        completedCount: 1,
        isAdPlaying: true,
      );
      expect(d.action, PlaybackLoopAction.continuePlaying);
      expect(d.nextCompletedCount, isNull);
    });

    test('ad playing → does not trigger completeTarget', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 3,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluate(
        positionSeconds: 30,
        completedCount: 2,
        isAdPlaying: true,
      );
      expect(d.action, PlaybackLoopAction.continuePlaying);
    });

    test('ad playing flag default false preserves prior behaviour', () {
      const looper = PlaybackLooper(
        startSeconds: 10,
        endSeconds: 30,
        targetRepeatCount: 5,
        loopEnabled: true,
        countInEnabled: false,
      );
      final d = looper.evaluate(positionSeconds: 30, completedCount: 1);
      expect(d.action, PlaybackLoopAction.seekBack);
    });
  });
}
