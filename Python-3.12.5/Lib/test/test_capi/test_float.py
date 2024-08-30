import math
import sys
import unittest
import warnings

from test.test_capi.test_getargs import (Float, FloatSubclass, FloatSubclass2,
                                         BadIndex2, BadFloat2, Index, BadIndex,
                                         BadFloat)
from test.support import import_helper

_testcapi = import_helper.import_module('_testcapi')

NULL = None

# For PyFloat_Pack/Unpack*
BIG_ENDIAN = 0
LITTLE_ENDIAN = 1
EPSILON = {
    2: 2.0 ** -11,  # binary16
    4: 2.0 ** -24,  # binary32
    8: 2.0 ** -53,  # binary64
}

HAVE_IEEE_754 = float.__getformat__("double").startswith("IEEE")
INF = float("inf")
NAN = float("nan")


class CAPIFloatTest(unittest.TestCase):
    def test_check(self):
        # Test PyFloat_Check()
        check = _testcapi.float_check

        self.assertTrue(check(4.25))
        self.assertTrue(check(FloatSubclass(4.25)))
        self.assertFalse(check(Float()))
        self.assertFalse(check(3))
        self.assertFalse(check(object()))

        # CRASHES check(NULL)

    def test_checkexact(self):
        # Test PyFloat_CheckExact()
        checkexact = _testcapi.float_checkexact

        self.assertTrue(checkexact(4.25))
        self.assertFalse(checkexact(FloatSubclass(4.25)))
        self.assertFalse(checkexact(Float()))
        self.assertFalse(checkexact(3))
        self.assertFalse(checkexact(object()))

        # CRASHES checkexact(NULL)

    def test_fromstring(self):
        # Test PyFloat_FromString()
        fromstring = _testcapi.float_fromstring

        self.assertEqual(fromstring("4.25"), 4.25)
        self.assertEqual(fromstring(b"4.25"), 4.25)
        self.assertRaises(ValueError, fromstring, "4.25\0")
        self.assertRaises(ValueError, fromstring, b"4.25\0")

        self.assertEqual(fromstring(bytearray(b"4.25")), 4.25)

        self.assertEqual(fromstring(memoryview(b"4.25")), 4.25)
        self.assertEqual(fromstring(memoryview(b"4.255")[:-1]), 4.25)
        self.assertRaises(TypeError, fromstring, memoryview(b"4.25")[::2])

        self.assertRaises(TypeError, fromstring, 4.25)

        # CRASHES fromstring(NULL)

    def test_fromdouble(self):
        # Test PyFloat_FromDouble()
        fromdouble = _testcapi.float_fromdouble

        self.assertEqual(fromdouble(4.25), 4.25)

    def test_asdouble(self):
        # Test PyFloat_AsDouble()
        asdouble = _testcapi.float_asdouble

        class BadFloat3:
            def __float__(self):
                raise RuntimeError

        self.assertEqual(asdouble(4.25), 4.25)
        self.assertEqual(asdouble(-1.0), -1.0)
        self.assertEqual(asdouble(42), 42.0)
        self.assertEqual(asdouble(-1), -1.0)
        self.assertEqual(asdouble(2**1000), float(2**1000))

        self.assertEqual(asdouble(FloatSubclass(4.25)), 4.25)
        self.assertEqual(asdouble(FloatSubclass2(4.25)), 4.25)
        self.assertEqual(asdouble(Index()), 99.)

        self.assertRaises(TypeError, asdouble, BadIndex())
        self.assertRaises(TypeError, asdouble, BadFloat())
        self.assertRaises(RuntimeError, asdouble, BadFloat3())
        with self.assertWarns(DeprecationWarning):
            self.assertEqual(asdouble(BadIndex2()), 1.)
        with self.assertWarns(DeprecationWarning):
            self.assertEqual(asdouble(BadFloat2()), 4.25)
        with warnings.catch_warnings():
            warnings.simplefilter("error", DeprecationWarning)
            self.assertRaises(DeprecationWarning, asdouble, BadFloat2())
        self.assertRaises(TypeError, asdouble, object())
        self.assertRaises(TypeError, asdouble, NULL)

    def test_getinfo(self):
        # Test PyFloat_GetInfo()
        getinfo = _testcapi.float_getinfo

        self.assertEqual(getinfo(), sys.float_info)

    def test_getmax(self):
        # Test PyFloat_GetMax()
        getmax = _testcapi.float_getmax

        self.assertEqual(getmax(), sys.float_info.max)

    def test_getmin(self):
        # Test PyFloat_GetMax()
        getmin = _testcapi.float_getmin

        self.assertEqual(getmin(), sys.float_info.min)

    def test_pack(self):
        # Test PyFloat_Pack2(), PyFloat_Pack4() and PyFloat_Pack8()
        pack = _testcapi.float_pack

        self.assertEqual(pack(2, 1.5, BIG_ENDIAN), b'>\x00')
        self.assertEqual(pack(4, 1.5, BIG_ENDIAN), b'?\xc0\x00\x00')
        self.assertEqual(pack(8, 1.5, BIG_ENDIAN),
                         b'?\xf8\x00\x00\x00\x00\x00\x00')
        self.assertEqual(pack(2, 1.5, LITTLE_ENDIAN), b'\x00>')
        self.assertEqual(pack(4, 1.5, LITTLE_ENDIAN), b'\x00\x00\xc0?')
        self.assertEqual(pack(8, 1.5, LITTLE_ENDIAN),
                         b'\x00\x00\x00\x00\x00\x00\xf8?')

    def test_unpack(self):
        # Test PyFloat_Unpack2(), PyFloat_Unpack4() and PyFloat_Unpack8()
        unpack = _testcapi.float_unpack

        self.assertEqual(unpack(b'>\x00', BIG_ENDIAN), 1.5)
        self.assertEqual(unpack(b'?\xc0\x00\x00', BIG_ENDIAN), 1.5)
        self.assertEqual(unpack(b'?\xf8\x00\x00\x00\x00\x00\x00', BIG_ENDIAN),
                         1.5)
        self.assertEqual(unpack(b'\x00>', LITTLE_ENDIAN), 1.5)
        self.assertEqual(unpack(b'\x00\x00\xc0?', LITTLE_ENDIAN), 1.5)
        self.assertEqual(unpack(b'\x00\x00\x00\x00\x00\x00\xf8?', LITTLE_ENDIAN),
                         1.5)

    def test_pack_unpack_roundtrip(self):
        pack = _testcapi.float_pack
        unpack = _testcapi.float_unpack

        large = 2.0 ** 100
        values = [1.0, 1.5, large, 1.0/7, math.pi]
        if HAVE_IEEE_754:
            values.extend((INF, NAN))
        for value in values:
            for size in (2, 4, 8,):
                if size == 2 and value == large:
                    # too large for 16-bit float
                    continue
                rel_tol = EPSILON[size]
                for endian in (BIG_ENDIAN, LITTLE_ENDIAN):
                    with self.subTest(value=value, size=size, endian=endian):
                        data = pack(size, value, endian)
                        value2 = unpack(data, endian)
                        if math.isnan(value):
                            self.assertTrue(math.isnan(value2), (value, value2))
                        elif size < 8:
                            self.assertTrue(math.isclose(value2, value, rel_tol=rel_tol),
                                            (value, value2))
                        else:
                            self.assertEqual(value2, value)


if __name__ == "__main__":
    unittest.main()
