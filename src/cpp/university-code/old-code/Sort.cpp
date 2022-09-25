#include <ctime>
#include <iomanip>
#include <iostream>

using namespace std;

class Sort {
   private:
    int* a;
    int n;
    int k;

   public:
    Sort() : a(0), n(0), k(0) {}

    void init() {
        n = 10;
        a = new int[n];
        for (int i = 0; i != n; ++i) a[i] = rand() % 100;
        k = 5;
    }

    void swap(int& x, int& y) const {
        int temp = x;
        x = y;
        y = temp;
    }

    void output() {
        for (int i = 0; i != n; ++i) cout << setw(5) << a[i];
        cout << endl;
        delete[] a;
        a = 0;
    }

    //ѡ���㷨
    void choose_sort() {
        init();
        choose_sort(0, n - 1);
        cout << "ѡ���㷨�� ";
        output();
    }
    void choose_sort(const int& low, const int& high) {
        for (int i = low; i != high; ++i) {
            int key = i;
            for (int j = i + 1; j != high + 1; ++j) {
                if (a[key] > a[j]) key = j;
            }
            if (key != i) swap(a[key], a[i]);
        }
    }

    //ð������
    void bubble_sort() {
        init();
        bubble_sort(0, n - 1);
        cout << "ð������ ";
        output();
    }
    void bubble_sort(const int& low, const int& high) {
        for (int i = low; i != high; ++i) {
            for (int j = high; j != i; --j) {
                if (a[j] < a[j - 1]) swap(a[j], a[j - 1]);
            }
        }
    }

    //˫ð������
    void double_bubble_sort() {
        init();
        double_bubble_sort(0, n - 1);
        cout << "˫ð������ ";
        output();
    }
    void double_bubble_sort(const int& low, const int& high) {
        int i = low;
        int j = high;
        while (i != j) {
            int temp = i;
            for (int k = i; k != j; ++k) {
                if (a[k] > a[k + 1]) {
                    swap(a[k], a[k + 1]);
                    temp = k;
                }
            }
            j = temp;
            for (int k = j; k != i; --k) {
                if (a[k] < a[k - 1]) {
                    swap(a[k], a[k - 1]);
                    temp = k;
                }
            }
            i = temp;
        }
    }

    //ֱ�Ӳ�������
    void straight_insert_sort() {
        init();
        straight_insert_sort(0, n - 1);
        cout << "ֱ�Ӳ������� ";
        output();
    }
    void straight_insert_sort(const int& low, const int& high) {
        for (int i = low + 1; i != high + 1; ++i) {
            int key = a[i];
            int j = i;
            while (j != low && a[j - 1] > key) {
                a[j] = a[j - 1];
                --j;
            }
            a[j] = key;
        }
    }

    //�۰��������
    void insert_sort() {
        init();
        insert_sort(0, n - 1);
        cout << "�۰�������� ";
        output();
    }
    void insert_sort(const int& low, const int& high) {
        for (int k = low + 1; k != high + 1; ++k) {
            int key = a[k];
            int i = low;
            int j = k - 1;
            while (i <= j) {
                int mid = (i + j) / 2;
                if (a[mid] > key)
                    j = mid - 1;
                else
                    i = mid + 1;
            }
            for (j = k; j != i; --j) a[j] = a[j - 1];
            a[i] = key;
        }
    }

    //�ݹ��������
    void insert_sort_digui() {
        init();
        insert_sort_digui(0, n - 1);
        cout << "�ݹ�������� ";
        output();
    }
    void insert(const int& low, const int& high) {
        int key = a[high];
        int i = high;
        while (i != low && a[i - 1] > key) {
            a[i] = a[i - 1];
            --i;
        }
        a[i] = key;
    }
    void insert_sort_digui(const int& low, const int& high) {
        if (low != high) {
            insert_sort_digui(low, high - 1);
            insert(low, high);
        }
    }

    //�鲢����
    void merge_sort() {
        init();
        merge_sort(0, n - 1);
        cout << "�鲢���� ";
        output();
    }
    void merge(const int& low, const int& mid, const int& high) {
        int* p = new int[high - low + 1];
        int i = low;
        int j = mid + 1;
        int k = 0;
        while (i != mid + 1 && j != high + 1) {
            if (a[i] < a[j])
                p[k++] = a[i++];
            else
                p[k++] = a[j++];
        }
        while (i != mid + 1) p[k++] = a[i++];
        while (j != high + 1) p[k++] = a[j++];
        for (i = low; i != high + 1; ++i) a[i] = p[i - low];
        delete[] p;
        p = 0;
    }
    void merge_sort(const int& low, const int& high) {
        if (low < high) {
            int mid = (low + high) / 2;
            merge_sort(low, mid);
            merge_sort(mid + 1, high);
            merge(low, mid, high);
        }
    }

    //�鲢��������
    void merge_insert_sort() {
        init();
        merge_insert_sort(0, n - 1);
        cout << "�鲢�������� ";
        output();
    }
    void merge_insert_sort(const int& low, const int& high) {
        if (high - low < k)
            straight_insert_sort(low, high);
        else {
            int mid = (low + high) / 2;
            merge_insert_sort(low, mid);
            merge_insert_sort(mid + 1, high);
            merge(low, mid, high);
        }
    }

    //��������
    void quick_sort() {
        init();
        quick_sort(0, n - 1);
        cout << "�������� ";
        output();
    }
    int partition(const int& low, const int& high) {
        int i = low;
        int j = high;
        int key = a[i];
        while (i != j) {
            while (i != j && a[j] >= key) --j;
            a[i] = a[j];
            while (i != j && a[i] <= key) ++i;
            a[j] = a[i];
        }
        a[i] = key;
        return i;
    }
    void quick_sort(const int& low, const int& high) {
        if (low < high) {
            int temp = partition(low, high);
            quick_sort(low, temp - 1);
            quick_sort(temp + 1, high);
        }
    }
};

int main() {
    Sort sort;
    while (true) {
        cout << "����" << endl;
        cout << "1 ѡ������" << endl;
        cout << "2 ð������" << endl;
        cout << "3 ˫ð������" << endl;
        cout << "4 ֱ�Ӳ�������" << endl;
        cout << "5 �۰��������" << endl;
        cout << "6 �ݹ��������" << endl;
        cout << "7 �鲢����" << endl;
        cout << "8 �鲢��������" << endl;
        cout << "9 ��������" << endl;
        cout << "0 �˳�" << endl;
        int choose;
        cout << "��ѡ�� ";
        cin >> choose;
        if (choose == 0) break;
        switch (choose) {
            case 1:
                sort.choose_sort();
                break;
            case 2:
                sort.bubble_sort();
                break;
            case 3:
                sort.double_bubble_sort();
                break;
            case 4:
                sort.straight_insert_sort();
                break;
            case 5:
                sort.insert_sort();
                break;
            case 6:
                sort.insert_sort_digui();
                break;
            case 7:
                sort.merge_sort();
                break;
            case 8:
                sort.merge_insert_sort();
                break;
            case 9:
                sort.quick_sort();
                break;
            default:
                cout << "�������" << endl;
                break;
        }
        system("pause");
        system("cls");
    }
    return 0;
}