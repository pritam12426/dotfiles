#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

void printbin(long long val) {
  int count          = 63;
  char binstr[65]    = { 0 };

  printf("Binary of %lld is: (", val);

  if (!val) {
    printf("0b0");
    return;
  }

  if (val < 0) {
    val = ~val + 1;
    if (val > 0) { printf("-0b"); }
  } else {
    printf("0b");
  }

  while (val && count >= 0) {
    binstr[count--] = "01"[val & 1];
    val >>= 1;
  }

  count++;
  printf("| %08s)\n", binstr + count);
}


int countOfInt(int x) {
  int _count = 0;

  if (x == 0) return 1;

  while (x != 0) {
    x /= 10;
    _count++;
  }

  return _count;
}


int intArrLargestNum(int *_arr, unsigned long _len) {
  int max = 0;
  for (int i = 0; i < _len; i++) {
    if (max < _arr[i]) max = _arr[i];
  }

  return max;
}


void chStrLower(char *_content) {
  for (int i = 0; ((_content[i]) != '\0'); i++) {
    if (_content[i] >= 65 && _content[i] <= 90) {
      _content[i] = (_content[i] + 32);
    }
  }
}


void chStrUpper(char *_content) {
  for (int i = 0; ((_content[i]) != '\0'); i++) {
    if (_content[i] >= 97 && _content[i] <= 122) {
      _content[i] = (_content[i] - 32);
    }
  }
}


void chStrTitle(char *_content) {
  chStrLower(_content);

  if (_content[0] >= 97 && _content[0] <= 122) {
    _content[0] = (_content[0] - 32);
  }

  for (int i = 0; ((_content[i]) != '\0'); i++) {
    if ((!((_content[i] >= 65 && _content[i] <= 90) ||
           (_content[i] >= 97 && _content[i] <= 122)))) {
      if ((_content[i + 1] >= 65 && _content[i + 1] <= 90) ||
          (_content[i + 1] >= 97 && _content[i + 1] <= 122)) {
        _content[i + 1] = (_content[i + 1]) - 32;
      }
    }
  }
}


void chStrReplace(char *_content, const char _which, const char _what) {
  for (int i = 0; ((_content[i]) != '\0'); i++) {
    if (_content[i] == _which) _content[i] = _what;
  }
}

void strSwitchCase(char *_content) {
  for (int i = 0; ((_content[i]) != '\0'); i++) {
    if (_content[i] >= 65 && _content[i] <= 90) {
      _content[i] = (_content[i] + 32);
    } else if (_content[i] >= 97 && _content[i] <= 122) {
      _content[i] = (_content[i] - 32);
    }
  }
}


void printNTime(const char _what, const unsigned _time, bool _new_line) {
  for (int i = 1; i <= _time; i++) {
    putchar((int)_what);
  }

  if (_new_line) putchar((int)'\n');
}


bool strEndWith(const char *_content, const char *_ends) {
  unsigned long _len_ends    = strlen(_ends);
  unsigned long _len_content = strlen(_content);

  if (_len_content < _len_ends) return false;

  for (int i = 0; ((_ends[i]) != '\0'); i++) {
    // printf("end > %c contn %c\n", _content[(_len_content - i - 1)],
    // _ends[(_len_ends - i - 1)]);
    if (_content[(_len_content - i - 1)] != _ends[(_len_ends - i - 1)])
      return false;
  }

  return true;
}


void bubbleSort(int *_arr, size_t _len) {
  for (int i = 0; i < _len; i++) {
    for (int j = 0; j < (_len - i - 1); j++) {
      if (_arr[j] > _arr[j + 1]) {
        _arr[j] ^= _arr[(j + 1)] ^= _arr[j] ^= _arr[(j + 1)];
      }
    }
  }
}


void intArrPrint(int *_arr, const unsigned long _len, const char *mess) {
  int first_width  = countOfInt(intArrLargestNum(_arr, _len));
  int second_width = countOfInt(_len);

  mess = (mess == NULL) ? "Array" : mess;

  for (int i = 0; i < _len; i++) {
    printf("%s_at_index[\033[1;35m%*d\033[0m] = \033[1;36m%*d\033[0m\n", mess,
           second_width, i, first_width, _arr[i]);
    // printf("%s_at_index[%d] = %d\n", mess, i, _arr[i]);
  }
}
