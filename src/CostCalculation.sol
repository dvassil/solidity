// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************************************
 * Καθορισμός παραμέτρων Κόστους αναλόγως την κλίση της οδού από τον πίνακα στο  link
 * https://www.e-nomothesia.gr/kat-ekpaideuse/koine-upourgike-apophase-50025-2018.html
 * Πίνακας "Ε.Δ.Χ. όχημα"
 * Ο υπολογισμός γίνεται με πολύ απλοποιημένη μορφή...
 **************************************************************************************/
contract Syntelestis {

    address private owner;

    // Define fixed-point math scale (6 decimals)
    uint256 private constant SCALE = 1e6;

    // Mapping for data storage
    mapping(string => mapping(string => uint256)) private syntelestis;

    constructor() {
        unchecked {
            // Αρχικές τιμές από τον πίνακα "Ε.Δ.Χ. όχημα" στο link
            // https://www.e-nomothesia.gr/kat-ekpaideuse/koine-upourgike-apophase-50025-2018.html
            owner = msg.sender;
            syntelestis["ektos"]["mikri"] = 0.90e6;
            syntelestis["ektos"]["megali"] = 1.00e6;
            syntelestis["entos"]["mikri"] = 1.10e6;
            syntelestis["entos"]["megali"] = 1.20e6;
            syntelestis["multiplier"]["taxi"] = 1.11e6;
            syntelestis["multiplier"]["small bus"] = 1.00e6;
            syntelestis["multiplier"]["big bus"] = 1.00e6;
        }
    }

    function setEktosPoleosMikriKlisi(uint256 value) public {
        syntelestis["ektos"]["mikri"] = value;
    }

    function getEktosPoleosMikriKlisi() public view returns (uint256) {
        return syntelestis["ektos"]["mikri"];
    }

    function setEktosPoleosMegaliKlisi(uint256 value) public {
        syntelestis["ektos"]["megali"] = value;
    }

    function getEktosPoleosMegaliKlisi() public view returns (uint256) {
        return syntelestis["ektos"]["megali"];
    }

    function setEntosPoleosMikriKlisi(uint256 value) public {
        syntelestis["entos"]["mikri"] = value;
    }

    function getEntosPoleosMikriKlisi() public view returns (uint256) {
        return syntelestis["entos"]["mikri"];
    }

    function setEntosPoleosMegaliKlisi(uint256 value) public {
        syntelestis["entos"]["megali"] = value;
    }

    function getEntosPoleosMegaliKlisi() public view returns (uint256) {
        return syntelestis["entos"]["megali"];
    }

    function setMultiplier(string calldata vehicle, uint256 value) public {
        syntelestis["multiplier"][vehicle] = value;
    }

    function getMultiplier(string calldata vehicle)
        public
        view
        returns (uint256)
    {
        return syntelestis["multiplier"][vehicle];
    }
}

/***********************************************************
 * Υπολογισμός Κόστους Δρομολογίου
 *----------------------------------------------------------
 * Για να γίνει κλήση των συναρτήσεων πρέπει να καλέσουμε
 * αρχικά την setSyntelestiKlisis με παράμετρο τη διεύθυνση
 * κάποιου contract Syntelestis, ώστε να γνωρίζει τους
 * συντελεστές κλίσης του δρόμου.
 * Μετά μπορούμε να καλέσουμε τις συναρτήσεις
 * CalculateTaxiCost για να υπολογίσουμε πόσο κοστίζει μια
 *      διαδρομή (και να αποθηκεύσουμε το αποτέλεσμα).
 * GetTaxiCost για να υπολογίσουμε πόσο κοστίζει μια
 *      διαδρομή (χωρίς όμως να αποθηκεύσουμε το αποτέλεσμα).
 * GetTaxiCostWithKey για να πάρουμε το κόστος κάποιου
 *      υπολογισμένου δρομολογίου με βάση το κλειδί
 *      (εάν το είχαμε υπολογίσει εμείς)
 ***********************************************************/

contract CostCalculation {
event costCalculated(bytes32);
    uint256 private constant SCALE = 1e6;

    struct CalculationData {
        address owner;
        uint256 syntelestisEntosMikri;
        uint256 syntelestisEntosMegali;
        uint256 syntelestisEktosMikri;
        uint256 syntelestisEktosMegali;
        uint256 syntelestisMultiplier;
        uint256 apostasiEntosMikri;
        uint256 apostasiEntosMegali;
        uint256 apostasiEktosMikri;
        uint256 apostasiEktosMegali;
        uint256 fuelPrice;
        uint256 calculatedCost;
    }

    // Για να αποθηκεύουμε τα data
    mapping(bytes32 => CalculationData) private data;

    // Για να γνωρίζουμε αν έχει υπολογιστεί το κόστος
    mapping(bytes32 => bool) private dataExists;

    //Προσωρινή αποθήκευση των συντελεστών με τους οποίους θα γίνουν οι υπολογισμοί κόστους
    Syntelestis public syntelestis;

    function setSyntelestiKlisis(Syntelestis _syntelestis) public {
        syntelestis = _syntelestis;
    }

    //Υπολογισμός του κόστους μιας διαδρομής TAXI
    function GetTaxiCost(
        uint256 entosMikriApostasi,
        uint256 entosMegaliApostasi,
        uint256 ektosMikriApostasi,
        uint256 ektosMegaliApostasi,
        uint256 fuelPrice
    )
        public
        view
        returns (
            bool,
            bytes32,
            uint256
        )
    {
        unchecked {
            Syntelestis temp = syntelestis;

            CalculationData memory hashdata = CalculationData(
                msg.sender,
                temp.getEntosPoleosMikriKlisi(),
                temp.getEntosPoleosMegaliKlisi(),
                temp.getEktosPoleosMikriKlisi(),
                temp.getEktosPoleosMegaliKlisi(),
                syntelestis.getMultiplier("taxi"),
                entosMikriApostasi,
                entosMegaliApostasi,
                ektosMikriApostasi,
                ektosMegaliApostasi,
                fuelPrice,
                0
            );

            bytes32 key = keccak256(abi.encode(hashdata));

            if (dataExists[key]) {
                return (true, key, data[key].calculatedCost);
            }

            //Υπολογισμός του κόστους
            uint256 result = 0;

            result =
                entosMikriApostasi * temp.getEntosPoleosMikriKlisi() +
                entosMegaliApostasi * temp.getEntosPoleosMegaliKlisi() +
                ektosMikriApostasi * temp.getEktosPoleosMikriKlisi() +
                ektosMegaliApostasi * temp.getEktosPoleosMegaliKlisi();
            result =
                ((((result / SCALE) * fuelPrice) / SCALE) *
                    temp.getMultiplier("taxi")) /
                SCALE;

            return (false, key, result);
        }
    }

    //Ανάκτηση μιας υπολογισμένης διαδρομής (από το hash)
    function GetTaxiCostWithKey(bytes32 key)
        public
        view
        returns (bool, uint256)
    {
        unchecked {
            require(dataExists[key], "Key not found in stored calculations");

            return (true, data[key].calculatedCost);
        }
    }

    //Υπολογισμός και αποθήκευση του κόστους μιας διαδρομής
    function CalculateTaxiCost(
        uint256 entosMikriApostasi,
        uint256 entosMegaliApostasi,
        uint256 ektosMikriApostasi,
        uint256 ektosMegaliApostasi,
        uint256 fuelPrice
    ) public returns (bytes32, uint256) {
        unchecked {
            uint256 syntelestisEntosMikri = syntelestis.getEntosPoleosMikriKlisi();
            uint256 syntelestisEntosMegali = syntelestis.getEntosPoleosMegaliKlisi();
            uint256 syntelestisEktosMikri = syntelestis.getEktosPoleosMikriKlisi();
            uint256 syntelestisEktosMegali = syntelestis.getEktosPoleosMegaliKlisi();

            CalculationData memory temp = CalculationData(
                msg.sender,
                syntelestisEntosMikri,
                syntelestisEntosMegali,
                syntelestisEktosMikri,
                syntelestisEktosMegali,
                syntelestis.getMultiplier("taxi"),
                entosMikriApostasi,
                entosMegaliApostasi,
                ektosMikriApostasi,
                ektosMegaliApostasi,
                fuelPrice,
                0
            );

            bool found;
            bytes32 key;

            (found, key, temp.calculatedCost) = GetTaxiCost(
                entosMikriApostasi,
                entosMegaliApostasi,
                ektosMikriApostasi,
                ektosMegaliApostasi,
                fuelPrice
            );

            if (found == false) {
                data[key] = temp;
                dataExists[key] = true;
            }
           
            emit costCalculated(key);
            return (key, temp.calculatedCost);
        }
    }

}