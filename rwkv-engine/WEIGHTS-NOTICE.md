# Model weights notice

The code in the anki-rwkv repository is released under the MIT License. The trained model weights
(the `weights.*.bin` and `master.pth` files in the releases and on Hugging Face) are **not** covered
by the MIT License.

- **Training data.** The models were trained on the anki-revlogs-10k dataset
  (https://huggingface.co/datasets/open-spaced-repetition/anki-revlogs-10k). Its terms allow use for
  memory research, and by university students and individuals for their own research; other uses need
  permission from the dataset's owners (see the dataset's LICENSE file). The weights contain no rows of
  the dataset, and the test vectors in the packages come from synthetic users.
- **Teacher model.** The models were trained with targets from the srs-benchmark RWKV checkpoint
  (https://github.com/open-spaced-repetition/srs-benchmark), which has no license yet.
- **Architecture code.** The model code comes from srs-benchmark and rwkv-anki-autoresearch (no license
  file yet) and from RWKV-LM by BlinkDL (Apache-2.0).

Whether models trained on the dataset may be redistributed and shipped in applications is an open
question upstream (https://github.com/open-spaced-repetition/srs-benchmark/issues/353). Until it is
settled, use the weights for personal and research use only, and ask the dataset's owners before shipping
them in an application, in particular a commercial one. This notice will be updated once permission is
clarified. This is not legal advice.
