ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �`#Z �=�r��r�Mr�A��)U*�}��V�Z$ Ey�,x�h��DR�%��;�$D�qE):�O8U���F�!���@^�3 ��Dٔh�]%����tO�LX��&�C��j[	�ܭۖgV�ݖ��~@ ��d��K��'��(?��H�H�Ę�!��<��6B�\����x���pFlG��u�"�p�C�3]#�:�!�	{��7�źI��&n��~.��[�i�n���։��M)�ڶl��I"B+k�N��p&q;��d�URÞ�����%���^�Q������_#�p�ֵP������l��{T��q�F��˿��A�eQ�>Bʽs2�r��0�.�v��Y�v����_�y�EI��Ũ"E%)����B����!R��H;α<[#�_~��*���6յ�|�TK[�K��T���G�x���ݩ�S�a�*�a�,��
&�?�}:��U�Ee!����0A�5�`��b�Ֆn���M	�M�%!N��8ȿ$D��|`!�_7L��6֚�·O˼�:���|���(�n�����\��C��2ί#��d�Wi~�IDQ��?�J���n��E�6�Q��9ȵ�Zmv��oS�31,��e#��V�EL�N�EmϦ�:A�m[?�����GX�M _w-���lC�w��A]wY9H�l��4\���G"���*a�jE&nR��e8aZ�_����6,�5l����ϟ�k�tX�*�M���p�9M��XvՁ�7>KC������X7{)�ex�C��;F��dg�܊�����~F�p�h�P�~�t���?[#4�x�(��4i�JLM'C4)&���h8{���P�B��İ�����$�rze�����������-�?�a�����.��O�\��I�$(ѸL�?Q��0l�qO��P�35�����.jꆁ�YE6iYg	�=�����P�����j?}�]rܞ����ʦj;(�����jM�`A�a�<z���4AE�a!~ꣴ1T{����(6bz�A�
���2Wӡri�r<\�tc�E��^�w��n!F�j��+ڋ�~Zý�NI��!@��c>
볽�����6�q��m��!�}YX�i�}�j;���<5-���LZ���-������Bh{lY��e2Կ�4}s8��Ks{;V��k}@.
��=�e�(�U�n:����J�~� �!�!�\�i�ZY̰A/�����S69��u6�^'(�9O+�q���t�[@����8� &�5Z�2�	ε���U�)o�x1@����w͋�k�G�u7H'ָ�e�������N�{�������1%]��������0��T��e�y��X\����b|!�� �NJ�a|���s`[4,=j�ٖ�s��ݴqŷ�<ۦ@i��c�].�+n|�6��[���R���+o��������+�������
e��ʡ0r�j��K�?�K������ؼ#Hw�g:�]��Z���Q;y�?��Kh��d�!7���XY�f��r��RY-�ߗs���A�f�G�&�.*�C`��γkM)�!*~�Yh���?�B�wϗWh0���Z�X�ƟвMлw��0��FV�Q,q�L�U!6�^� �`V)iY�'S:ޡ#A��$��w�G�E��i(��,⿢5���'�g[tKq��`��'��c���8��ܿ�Ǽj&���rfM�NT����UQͶZ�L�JX@(��=��|��"}`���a۽Op��GEa���ˋ�߹���?��S;'f��t�0P(ڡ����B��K���&����4{���E��<`��3g�Y0M��?�%��9�]��K���xtt�G�F��.0v���n�e�n;."�m٫�m���Zج:a���!rFW{�ҳ.�B�<�pj1���ǖ�P�۷��OdK�e�����K��Es����1F�=�(0"�����pTڻ�B��z9�?pf�LY���i��#���B!���	�c��&a'�`
1�)F{�&U�UN�ǡ�Xp�fU	9V����3g��sg�;���}൙Vi࠙�� w���\
���Sg����$����Jl�����T�G�5���� D��u_�b=:ᬂ�z-��h��0�`Ʒ	����BX�����ֈy�1,|ۏ���F�2R�����r)d��Ge1����(|����B����?��9��w����B��o�{�fMO���!0���FA4:zI7�ez|� �e�������~v(�#�ow�(���K��tY�IT�GQW+������B|@�P���!�Jɲ��*:��W���[o����A���Jz��+h@�����j?�g�:�������\���g��*=7k�32J(�t�l ���Au�{���>Af@�N��"���t���8>�O?��n�D�զfj�Cح.:��;�OQWG��G]8����������z$�,���qAxt�P�44L��G������W[v]�s�j����U@�.#�q��h;�|�`E:(��7��k[�9���@���5���{Y�z��K
0ZN;����Р|i���z�X�9QA�83��+��r��v�x㚗A��Z�9������M����x�E<�.*l���Z&0ip.@ "�(c\H<V�	Z|-*�����ɕ5-!KQ��ZZT4,��q�"�1N`YV��&���s����&��7!�hf�MZ���`�D(32Q9��Mv4�;Is��Ub��=�4�QT_�P{���7��B�ִ�@G��,�x0h�=�m��?ł�!��X=c|�)/c��-�0�(��/��F�`�I�s�xe�`� �K̠jR��c�}}>�]��Y�B���<�%I�����|���d�eK�7\�=&�n�ɧ�	^_f&l�Q��������4��W��Td�����������x���q"��~�f��������A>x?����%z��5F�Vإ��T9�=AP���B��*��Nn�i(h���x 0�rݭ�np�>��5���1�/��F�����n>s5yF��������w�eL��I���j����l� ���)>��w^�{��k����G�K�"�c���?Pb�z
����|��_%.�����o��߷�{��w�~�����?����������ǟI�"h�,%�j���r�*5Y[K$b�JB��8&�H䘜�$���儒H����"U�e�?����-7NxI]��o�v۠;�`�,qK�qI���G�/s\�2�vu���K��-�V�A�����ҟ�%���|�̀�s�c�@��?/��w�������?�_�����?-=���'�	�6�	z8?�w��s��/�����:>>�/
�?�����ޥ�)�_��_���
�����8��\>�Q~��z���o[}[=�X�q�����!���o�ۣ%��O��/yz^���s|�.��z�U�}j���!$QHf6sD�4r�\J-gX�[3�˥6OS)UK��N.��sE��횇���j$�ٵ^�u+�4�;��qn�:�]�
��h���67U� �l�S����̅ZL��@��j�M�U����Q�<{��yZ9}yzr󭩵�ޱd\Kk�e���a�3����E�;y�hT^'���rZ��󭴊}�|9#o͝�D��VC+��Z�p���地[�IG4픥	�����i���w:�������f�����"S�C��֥���})�࣓3����˙�|r�o�y���<��^.s�=>RN���i�"S�'��v:G�GE)*�/)�̺�湱�*�U����d~3���Y��	���L���NfKrjr�[�>O��R9h�������Sō�����W�-s�yt7��c��ngq���J>~?iw�k�R<��{�؉��n�;ۧ�rr'��0�m5��$#�}:�[����}�U�'��ZF=U�|ʡ���:��|j[�%[�	���\2�ִ�;��v�C��û�������JقY��U��2��*��|� ��O���~쭙��?T��D^�	�(i�'���BJ��A�0q��F�zIَY�«n��Z�6��:�D�+�5_����wSr"~V-Ս�&��Bz��WWW�H8��e�wt��@:fH���~�S��!}[@E��w����۲�����J���Yuw����s�}s�)��?��QP ���s�!;)�@ۙc�����6�`MVo[���BSj�.���Nr��#	�Y�=�Nv�C�$�&��#�83�i�]��M�k�ɕRբ}�r�
�v��y�ũ��C��2��R�ɇ̓�~Q�*Y�(�[Ҧ^O5����ʻ���F�^w'�UH�$�+�z��W���ܽ�����_���S�"� ���P�E��|�?���M�f���Y�$nV���E�f���Y$nV����=�f���Y�#n�o���}Eq�_��'_�����7�l��W��M_��/���&��������w��ɥ�ݿl���ov]J���xiu_K����w�L6}���W��qD���{��c��͞d��Ѽ��k�0[L4,K�����N��5ݖ��u�G����Y/�pZ�ol;p�}�^���'���M�p��W���̿�=|�������s�'(e��6���%���n��j�H�T$l^T��e��~���&���tb�����  �����G���u�G!�&5��YĬU�Q���\��M\�W%��UdZU��di�����K��*x �!T`?�=����º����kY�}�M)�6��(�a״h/�
1�A����q�}�↱2�1�-�q�����O�^{�<�id�L�'5��N޺82s���z�>��^���(�{�q��d��+��� rN��tDdx
��tz�u-����g�yF(8��nE��6�˔��V���d՗F�B@�5�� ��6��
i"���:q�vրAZ����{���v,K�Q��ɘ�!��H>x:��P����~a��(�����������e�s��.S�x�x��_��G��{���֫�~��(в��/٥�=�]�GG%�>�c�y�5��*���|u��J$�m�
���CߞaÃ�W�Rfh����KRn�"Թ�l��D���%�u,�y���&o�Ã�k�[�^b�Χ�'�;�Sq�N�%;vW�8;q��c��f��APo;쐘[�fB��`�;`�^�R�W����)?�Tr}ﹿ���{�\3��o�#�v{���Ҍ�7)�Rι��u%:� /����hn�1�\;������:WAn�e���$E�����9�P�����Y��/�&! i��s
���K��T������b.}�����Ӳ���j�E��ԇ^�d<9k6v�u�~�5]�Vz��a�$�?D�>�����+F��ƪ��?l�����n��?�=��59�Y�s`�H��`�?z�A�Pv���!��A�F3g0��9�^���+�3���,݋dk�u}����;ėm�^�� �$�1��z]#��߳L�@�Ens��{Ӷ�{+A��}�Ä5� �VC�|?�|�4}�	���͑S�F��n
�?��Bي˽|g��@˪�(�":5����nM�%�����е1���c���:.^�T2�}�#E&���ʃ=|�'��~���?��i��{ӿN��~������?����������>%�����{/���W���yz]C.&���R�d&�jrB��j:��*��Ҋ�$�Z�N%���T/K��Q	���r&K�I��&�؃�;����|��ӟ�I��_�ѧ�p���?z�����%��%b�����[ث�[v�oފ}�],b��f�o�A~���u��ج���~��������o���W]p^����(8�s%�:�dZ{�Y�5�>i�,���~:�Tk�:ǜ�+xt�]��88:�"g�]��y�b}��1�Y�;_^�R��g��w�ʊ!œ�B<���IWiK/��abQ\�VL�;\�H�y(��彮	�;�:�Ť;�.��97ϠwE�%$�Jo�KeT����\lݼ�2����(��N�p�Bk�!���p݂��p���t���WبƆu�HuX.3�{�꠴dGj�t/�m�K;�tڙ��ʩ�71mSs�|�To7�{C���ʼI��s��h�@Fz W�b>�r���D���,�^/�D&���K`|D�S��<�����2K^�����3Ag�u���^��4m�z�t��Ĝʧ#�[�݁E��u��Z�;�a09���/� �`=�����։�vd^l�͘�j�(�R�=}B�l��uV噞
Gf�E��y��rLa�a�%%U�pz L4���}1sh7���?��K��Ψ�Ψ�Ϩ�}{�Yd��+�N���RBirP��b��ID#˞��T��M���xyV�_��Yc�Bl���
��狈&��εEe��DO�-�
0({�E7��'~�@���Zj6N4
��,�`��^��$#�mK���Ҝ�+�.�CUQI��J�q�%�����-��6\S�֎�iM\K�������ϳ��t�b�{9&K%d,��+��Q��M�X����K�Ҫ�r����{��)3�9��،�gS1�h�v�6������ֳƒN:�AssTN3sά�����F��mU���&�������<��PYxa7^�}/�K�^���{�}��^��w}�/,�X��z�����J�7���������E>�j�Fo� �ڽ���m�v����k�>��^<��߱�=Ж�c/�^p^���[��b�;�o��"�\��|������ߏ��~����a�_\���+��Ty-�'3�J������§G)��;#�e�y��<�4��#����=���.Iq.�:Z��g����h�Q΅y����Ϻ\g��l+��U�|�
U���H������Ȳ.�ǯ'�Y��+"_L�R�Ti��Դ�I˦jT{~�fGD�:JJ��g���q0襘�H�z���:�.�ؙ~{u4ʗtC��-"�bGS��L�x$��N��L0�.�wx���ZT`%2�b\�!\P9�n�9VV���`��n0�~a/w��N;r�:h��:��5h3Bg�b�A�W����G�rX;*(�4h�F�DBҎ���
4=A+�=���]T��$a׹>�cm@��^w>.����	�ٌO�Bz0�Hx�[�M*�J�(�;�� �FuqV.�r��g�����<w��Y!���m9�b�U�|�B�b�#N�"�YVN�e�.+��/������;v]z�C:�	�����Pi��z�j"�.!W���Dul���9s]6k��)�Ҭr����qS���{öQoM��*?�(�m�5��6F�,W�u�ƌ3F�d�V�T�sZ����C�k�ȸ���{�rNd��#�6Ww��ۣ�H[z�F	z����f��nN��N��ɶN�C=W(�gDu lԅ#ʳ��Q����Z��J-u��y	c�}�ɧ]�/.	��IT�P,􇹢!�i��/]�ofİ� ����V���?y&���.����r-H��|T�����L$�lY�I�V�*��
�-0� Y���Į�#\$L��n��[��
,�aҀ�| P���r��,����a� 7ٳSf��c5��l���/$�>g3�6��w�MA'�՞4!d��6;�8�:e��2[-�pPH���ln`��`
%�u
H�%�*w���[?�\Y#�ح�y�X��N4r���P�Ģ��yC����̰�N�躲��z�f�st�]Ԙ��L����V��ъˬ�\t3y��"�Z8�U���9�\J�n��mV9��_DL�^�\�ƾt�����kQ�-,D�z���$�*��:�`�}]������N�b���~�y�����--'Z��+�˶eZa���ϱ��4��{3��=썧O��<}��y�����H����뱗��ȵg�������P6��!�E� ]ћХ^��qz{�(�c�3�n@�T�1�e��|��"�';�_���8gS4t��<_����0�:�l[�ct���o�=JG�]�|)�r{��w�|���О�Y\��=���%R�3��$uw�w����Bi��s~P�8�=�9��א��K��˩��0�P<���$پu��@�6>���Hs��p�D�a��A<˄�>�~�=��1�7lB���؂w������:>���>�����*��.6��h?^���o#Ǭ�E���yI�a��!g�1�;����0[������������R7=����v�8.E-A=�"�2D����l�c,h��YB�"��TC�z��E�Z���=0�	T���.��]�7y�����G��e�/��������*>ր̂���]><Q�:��K�9@�_����jȶ�5L#�pj<���A��>�D�[� �������!�Ƃ���}�#�޹fZd�������a��}ظ4���FjDP�(FL��5�\d�� ?9cض"��E������X�+����j��c�-�D�ي�mP`�ub������z��$�fP7�M�qϘ��>ް D�Y���'U'���	�˵'3`���]y�!���;�4��)�v��aߍ�ژ�o=�ME.��"J�kH��Բm��__�	
[0���h��ۦ"�i8��طh]�
T�}�7���rhH��ـ�Y�^$�6o	��-)�O���8|N���5�Ke�og�."���(l��S>��-{Ŭ)�9`���W����,[�
��HOS
y(�}A�'�ps�3�-�5H�rp�Y6�s�0����g��K<D6��r({f�~^0�Ww��^S�#���w�\�����^{���DL$�v����1�2���Nt/d'�M�p#�Ycgj�����4�F�e @��`lHy��^٨��H^��hW �D��@W��l�����Z`�����(`�g@��j٥�� �l�
�#�X�goe���kSC6A��u�{�fq~�f��l�h�jH��[��7	_<���L��)�� ����DP�_#�D�
�&o�F��b��;�� �D ��Gjf����`#t���Bp$����L��JU��QDN���b͍-gS7	��b��~� ���l"K�9E�r��M���E�Y�xLS���e"4o1F�n�+��0�ך}���)?w�%"r�vD���#�+D��]+��h_�8᷵����gC�]Z�%���4�܊�A'�w�?n��C���`D��i%;b.y�S߿B@t�9��Y߳�3lC��c�I\sz��|��Q��7��Va ���޽�<<��+T�^�����γ�#��*��tJ!eY��YR�餖���T��������L*I�?K�J_�gS2Ee4�L�0
.0(�"���[^�-���rZ� �`�=�Ƌ?)�ɣ�����1!�y0����@YYIѲ�(	*�H��J��K�YY�S)*���TFKʊ
C�I0���F�5BN������G��z��@oi��z��1�{r|�����Oy�ݓۅ� �u���;2^B�~���m�������7��q�Z(�|���)3��lBS�+�5�f�IiW�ssÿM�)�R��=A[��d�M^���9�.�T�)�͚�=�l�]�F:<�&�`��A@yVd�*ܝ�['�[p_-nO{q�p3��ٹ�$��A�B�KFoݸ�=�>���pmd{�m� L`|�8[����wo����6S�GyX�j���6x���R8��|c���\�*�*����ǳ��f�C�p��P�����b?��{��<�Ogc_�zlG������p�(�7��sFm-m����@�b�)媕�P8��R��8A�dt���Y��x�g3�Tz���gi68$��$�\�mJ09���a�&�$g�z�� ���9���+�,�*�t6C=W���r�<�Gݙ|җM[;����I��&Q���:D��M���tɇ�f㻑m7�o��5�E~Lv��
AW��6V�����έ���ر[Z��.f7�m��5���H��q�q�QUlN���#n�V?�����Z0�Ȼ<�A�(�J�������_��|��?K�;�������.��<�}�������LSw��W��7M�������}��ӿc�=�:a��[xnc����S�;�+�W���Db���P�����n�������a��}n��_��F�[������<wh�<��y�y�h�l�~��+���;�����ܖ���Y��Z"��3*xE$T���{�*����g�ښE��=�⻷j8�.v��"�"���]��(�
���?M:�=�3I�;�t�u�Jeң�������A�p� �fI�������Ux�����t~n4���~��(������I��럋Eko�x�&z����^�Ѯ����9�e��<>)����a��=�)~�aJwv���<qctjΉW�l�����9XK����V�h<:,��4&1><M�x+-wh"���������ф��������y6���	x�*��{����*��'����
T��3X���� �������4��W����6�]�[���_;���}��%h �?�����JT=����k������
4���r�S�ա*�����+���?��* Wu�U�pU�z�����?�����J� �x`�k��ϭ�������Eh��~hh������O��_^�������?�?�?Xr��ʓ��l����gY��g������}[�D~f���=D�������~"���,���ͬ2��߷������Mgf�̭�YK-��E����%�G3ť����v�����Ty�dI��AϜ�����,�v�8Y��8����\�^z��}��}"?�����d�fJ�%r�h{o�A�],S�9��4��g��b��S��)]+4qV�8�Hϑ3�%tي�shE;J��<+��1���4	��N��GBg�	���؃s�>h�.��\��8��߭h������ ��� 
%�z ��s�F�?��kC��R��F#����'������O���O����� �W���8���� ��s�F���g��O�W�F������h����������}���W�o�	�T�ra��f&�qR�7����_����_l}�N�]�{[�����Ύm)3�8�~N#)ѣ�����F�£ۜ�����;�ذZ�����F.���m��	��3�����lG�a�J�d둿��PЅ���+�;�.��l�W�dj*���������Ʒ��pd�KA�b�[�F�}Z����4�Ζk}�D���b�ba`�I�8^x��1w}b�ˏ[j�l���K��ӱ>�3�?0�C#��@����@��:�dyz��� ���[�5����>O�_���M������`A�� c�9��>����~�����lpA@2�ǰA�FL@�<�c!w�8��������W�_����}W[�c1�m�`�,͸ӡ�ϻ����S�]���>�;җ������D��'_YǴ�+�s�vG\�u�ٲ�����<�t�ْ��X9�"%�e�?Ć�0��;4��N~܎Ϊ7�B��[ф��?�C���@׷V4���W��0�S�����WX���	���W~��;�b5�u�N"6���;Z0g�u��ە��
������>���ј��K������xd�.�EaŁ$�]
[G�(�H����j]�B�.�-ۚl
�Ȃ��TL�P�wi�oE3��5����~���߀&���W}��/����/�����z�?��@#����?��W^�ny��5�QyG�𸙲���+�r�����W������%���e�Um-� ��?q �}x�U��q���J�]�� �yZ�������SR+�-����a�[mT�z��ooW�%�:R�����6�y�������\��U���o���*r��\󁾛D_^�-����J�; L�-�x�1R��U|"��O�Q4��i,�>�������T�3��d�h�.E����Ŗ�ފ�;U�Ǐ��q���7������5L;wm��{e �f3�+��l!��-�2��~L��ՠ/��*���J�E"!�7�ޥ&�^�pEt�\�vO�/�f/4A����G����Lx4U<���؃��[�;�|<������������L�Ƣ*�����[������!���!����'��kB%��=��=��1��ع7ǉ�
0��<�a(>d1��B���� <� �Rl�{��b燡	����/��J�+�݁\��Ρg��k��x,Hg�(���S%c�Tj���_k$��]�/�UR+=ݪ;�ܩU����xS��P��`3��Lp�Dt�3:vu�!��� �۶�ܴa���h���S����O%�x��E<��*�*��{��$��*��g���0�W��o��!㽉 �����	����r�n_���AU�������*�j����H_翍�`;6Z�9*v.锍Se��w��AY���,x/��
a,�����}����[+�����Q�Mh�q�Zt�Wg�;GN;�&�Y�-[��kL�6Y�9#/�����m=���Y�<M���܊cZg]��2gX�����q)�҉
me�b_�r����Y�gۍ�7�s����YQy�0�m��m�0P����ImF��ݥ<�x?�	��H�)Q�f2��D{ߞ��<=����m��J��v�c�$��H�,Zcҍѻ��v��<E-t�=Z�t�w�_$�gOs�	�ˮM�W���քj����T������	�O�$�քj����&��G��$��U����o����o�����8��'� 	���[�5����_*���/�
�4��?��%Y��U �!��!�������o�_������~iݯ�U<���
�%h�v��I��*P�?��c�n �����p�w]���!�f ��������������5���v�������Y��U�*�����*�?@��?��G8~
���]��?*B�l�����[�5�������� �������(�����J ��� ��� ��5�?����?��k�C��64��!�j4��?�� ��@��?@��?����?���Y��] ����_#�����W����+A����+G�?����������W[��B#��@����@��:�dyz��� ���[�5����>p�Cuh���U�X�2�X�ĸǇ��򹀧2$q����x8�z�����{E���>����	�O28��������������^��{u��?9P��ޭ6`���E�/ji����gw �1��Fg�$��-�A9��-q\�C���$e�c�v��.۞Ķ�1�����B���������3��8������G{@����/}�kc�&�e�K_��݋��o�p�C�g}������֊&�����C#��jC������j�~3>!������ï�À��s+�E���vH��/B����Q��_���9�;e�}�v�έ��%JZ6q8,�y�es1]b�q�yj��s[ݣ��(��Q�\�v现�uy8 ���Gy�]�
m��{+�q�����ߊЀ�?����{�o@�`��>������A��_��Ѐu�������������<��u��b/��D:0[kjf�'Ff���v���߳��I;YtE�����c��%�����zghK>��=CY��Ώ�.N!s��Ob��̓����N?�0�(�&Z0����2��23�K܏�UR�����I�^�M�/��-����I���i��.^?1R����NX	:������.E���Ƣ�sx�z�Xn"��c: �AfP���/�����eϾ��e}y!p:�ɘ���������?��x�[���ՄXTG�9�o�����<Z'yk�D��S���]lw4�7����
�$���yx�����xk����!����$��*���������9�q����	�����w%����D7�j,�x�?��F��_	������)��*P�?�zB�G�P��c��}���Z@��U����-I���5�C7Ns����Q�y�?_z�~ׁ+|�W��e�z����i�y����_��+M�����w�����{?^J~�ך�Y(ї�o�_��t1z)]�n��[��Z�|[2�[��/�VU�Zu�E���Y�-i:�@�v��I���i-�l��t��N�2a1!��kZjD(e���^"���@i1���8N:^vȤ䎧���!Źbj��-�T�{��y��vnr}��͔�ׂ,_�~����o�]T��>s92cQY�?��dK4�۲�B|�m3�ЮI�V!q���(�kWe��� ���Ĳ[��GT�6��������tʟ��i�P	A�xj�"5c���:ϰ���]dιYb���Tr�]7���@N��[�{A#�}7��ߊP��c}���|v�]y�_��]�M1��(#��"`)�_x$�3`���^��6�?
M�����W����W���L��n~T��������l������>3��ŜX�b�e��^�|�V��ȕ�Z�������o��w�h���_h���Y�^�A��T��������j�����c@�U�����V����Ԝ;�,���b(�h���]�ϳ���E��@�R�O��[�y_�o���3��[�yC�o���K�o�R�{)�!o���d�[]S,�v�=2�kɻa�^����I���l0՟u[����A��a��:E~v)!��r�i��X��Ʒ��޺�K�yP��|��Ģ�F��,:-i�b���{A��yֶ��DPg�RА�u?!����p��q{�l6c��)K����E�0�G�l�v� Ѯ�U���Ly��Kq.�$l��m��z�zb���ޕ69jl���
���l?�J�X$���6�Ҿ���(Y� $$����I��&uW��+O��*�$I��s3��t�g�~�~�����K�P�o$���32��*`�Y��hY�
G�T�b8 4EadR��Y�Q�.�dI��)��[�l.�:��#�x���������[�����)��Vd����6��̫���\"4��ڰ�Z6���-�j��T������{�a��/���2�����H�,�7�A�/D���a�/Z�1�@���?n�G���C��H���������?ę��e��	���������Q%-I�E����-do��2����o���W�S��ۧ�>w|���c~Q7NI��"�滅L-?�֧�m=?���6�&����i��4r�}���i�
�/]9�G���
��L�W���Rxa�<�*��t�{���׺<o�6�Q����q�eYP�M�f��s�`W��iLh���ɰ�%5y+k��Yz\���hY��
ޅ^����a���a�G���A�0�3�V ټ>Xlj������˛�>�V)n`,��(�T���R��b�R;K�Ձ�[����UUf��4�Jy0��&N����L�hR����Z��i������.�-�K�L,�R��5��~��3�Y� 	�+�;[�����I�������H��We��'����/	����Q�?��<$��?����(�;���h�'������������ǀ�.�D���[�%����|���Q"��!��Y�7�����H���o(�����#��=��a�����c�����O������,�;������i��"$�����������H����q�;�����?E���@�?E�8�先��������_H��Q !���BĄ�����?@�G�?"����?�����ą�_�	��(($~ ��u�D��,������("$>$��?��@(�C4@�P����@��H�E��P^�����׭���h�?6$��Q^�����,�����$@�P�����w��B�4�	�������1���[�%�������H��G���B"�4�?6���h�?���z��G�h�'&ĩ�f`����������_�?C���h�����WY�$�d�	#�9��؉��(@��<�2Y .H�fUMSr2��Ѐ�\�%X���^�I��{����������lK}��������ʼ^�kB�$l��N����K�x��B��o���Yv� 쮕!�ʶ+�0�Xge��T).'�)S�:}�_��h��p��[��F����Q/E��e/�Ǻ�i�d��E0���:Ͷ�Й3Jm�j�łϒ�P[���,^ϊ�V�6���w*潿wvSq7x���Ƈ��?G��I@�?���C����q���7���^/���������d�F�V�v����\5�T�����G�[���JuN�_�П5&�Fw�PT�n��bA��L�0H^=�d��劫�3jzY�z��,���/�&�ie`�jVr����ɻT[D��K���A��1!N���7��#6�?�����b��B�_(������b��A0F$B�1��� �������{�ר�[t<ݖ�Z�o�
B��8�W}s�w_żP�%�Qf�(��v�a{�xB⅚���`���]�=�����X���� 5ԂAj�y�6�v)��AIf��f���Բ6�'NFnɫ|֫n�&S�N������A��������y~��r�^��tW�E����a
�HZ�r����^vAR E��N�*y��_��J>�擠�+�f�'�ݮn.]�$[%�X[k9Jf9� ��"?�ۍ0ٌ�~AĤbv�����}q-�S���t�O+�Նe��Z"�Fy#�����"	��dP������� 4�#����?7�G\����B�?�?��܅�/�����?��C6!~ �G�7�Sę�g8����� �����?���������"A���`���5�?������0����I��2zD����������(��?���(���E"�y���H��C+@�
���n���G�?Ć��?Z�1$��g��I�	���؅��}���g׍�g
Ma������h�Y��܍6�C��c�G��c?��
��bg�؏�b���~���b�5�w��m��~O����~[��[,��+��T�i�ⴅ��&=XW'�Yo,I�S�h�ͪ����P��9��ߌi��j��pQ���T�a�/��q���_�Bܯ�vS�Ӻ���RJ�8ΗK�����6?*vlc�K�َ�b��~ys��氤�]��X�I��=6Dq���ny�Y/P�*,��4����6���k�v M+tZ�j�N��J�1{=��h�?6Į�,w[�F ��u�D�?��I���O�)��_��E���H����_(�����O�����_<�x�@�������@����@ �����������χ����,v�l�|״J�~��wk��5�_Կ����S�D}�.�su�ߞ�>����Ȯ�e1�޺tӪʔQ�JyYM��]���N�S��Q�ZL.�^����%�[e䵍Z�o�)��)gؠ�;�4'�}��1 X�51 X��v�m^��y���EJ�:�O'(�V�,��G����[[�5�SZ�$0^nQ/uz��H��ײԜ�i#�(��lJцd�(��û�_�D�?���/(�W$�]��-wK�N ��u�$�����1��?
$���ͩr��4VV�\V��PC(,���Q���T5B�McT�p,�e9j²������H�_Z�����r��.7�:&me�����vX�D�d]&��v��ۍ�6+���K���ܦ���JW�zJu\��z�٥ݕ>�ϱҌ���3�\_�'v�5��t�kV|sS*�&�rz���,t��Mb��h�ϗ"	�������p����#	���!����Ć���� t�n�W�$�?���÷����j>0�E�Y��	���3ZL��թ���:��!0������q�,{�%�8N��ޮ,z��:`0��v
}fHd��R���ɶn�V�[ש �QRT���v�9�=g��6�X4����"��l�����G����*��cD"����؀�P���B�_���8���I��A�/&<������{�wk�;��M-M�����-	�lJ�?^�c ����� �����L�V���KYn�D�sR-���|%+��(�~�NB���f�:g9˲���5�F%��i;F����WQ�dv��/�|*
��c���:O����:�<a�R5	B�W惰O�+�^Qj��x�R�  E
�?���N6[���R�$QIo��fg|oȳLi�� �Nn"��-u�K3+s�d�T��7�׋ؓāE��R��v�Ru���\���k�V�����m]�jv ���-F��ڝyjο5�59X�}�b(��XoMz#�MfF9�'?��;�mee�'7��e6��'hH�����Y�C��\�����h���<6�7[yu�خ�y�-���b�]��߾i���8w���f�.ߜ�A*��e<�ï��|an�3�������o�pǧKٲ��T��X�����a��a#|c��o)��v�$���x��~%~q���3>�ό��,��Q���C����J+��Vd��������q��5��|�����;�i��<��_�B�&���kxN�@���gd��V.���X~���%/ �,��\re���+�����£mw���۫7�����;�'^�y/��N��������/�	&�,;\�M�|	#��_5~��%��?\�[����lsxZ`}�bV~=	o4�aj����p�`�?|9�o��	fZ����C+{x`@�sW�eZ:>�L��5�o��y+�?��N�ow�u�Z����c.�ᕬ�B�P��ұ0o��ѽ�v.=<�#;�����K�خN>����O��ꡈk�������)�͝��6�/}2��<�l�6��U	�����yt���»f��~W�4�F�(����a�����L��+�\��a�au����~�x�/��k�i>7�������O�*CA����D�������d7��/� ��������~�����	��7_! �����&|_v����`��	�oo��=���4��a��zb�?�.X��	[V�E�U����`X!���P� ��]�׮��_������,�a����9~�����	lUS�{�?�4.Pi�p�n.dx����������h'������aA#{垚�m����֫t�~8����xn˓���$u�����3��(����w�ϐ5#d��
VV�e���r��\.%����v'�������Ƈ*����&o��.X� x�<U���T`���ģ;�E״W�1Q.����^��w�	?���+Bo�F����${��A��g
�x���T�����n*X�j u˖�����dpp�1�p��n_R(��?��Ic������P��뜶 �wX���w���O�/.3��x���������5����~ޟ������ K���~P`�}'�ϢlY����P�C�|*�����q�;k0����������	�x|��������ƛ_���������r�f�I�f�k� ӂ����ȰUY�M���w�p�,�'�:�����oj�v�a�����(��i�^�ɓ��z����y�"W��W{�����чV�l�i��שY��W+w~��cu�QO���a{��w�
��?��c��>������s���k��g�xW�e�J�Qe��w���`����׾��H�N�vw
|-�O����;�ɍ��u~ܥxj���H�p�P�Ӽkks��d���g�aǈ�w����y����?a;<��s�-�\��}��eY! �*�r��޵�8������ژٙ&{^[�KR�3���U�3�(i��t9�v���ҙi;�t�+3�\5jiw-���7$V�+,�+b.����#DD>�v���k�jF���.;����|��hLn�t+*��`HQL8*	1DD��F�X��BL�i&�����Z�^�֮��!�����MR�����HϘ~�';��.+ɪ�v�O�F����݀��Brg�����a���*z����&J3���9gu����Y\�
_���Δ>�8�T&ζ�z5b�ql��~�h��+�-ْeͩZ����1�}��PF�Ws��nxe�7�n����|��g#���ӵ�"p�Pg��e��/t.����W�s���ג�!}1Up��S4��B�����ky.+���-�e�0UhAC�kkW8�[�w#o�g>�W�=>�G�`at�P7����<���	�9�����Hp��c�����ky����_۸�yg�����|i덕M�GʡV@��`,�)��cB�զ�h,n�bA:d���0k�B�(�1&�Z�(lE��������*a�%�^e�Cm�U��
ڣ ^��& 	�4��5e4 �&����o��-�����<��qkAgk���@�x�x}�e����&۟`�/7�&��U��+^�?OE��<N�����b��#o?���S1���q���#�)��s�F���O&�����".��o�p�d��WAi&Y��v�}��*%�v�(k���ሓ�"�$;Į�������΋{ ���w���"wȤ�V4�r6�u�^	T���ʝMcR�%��"Y��H��G��
���Y�k�}_$\.�2y��m`��]7��U�"Ū,�}:ԋpQ����4��Æu�+������Yݴ4�9��y��m�g1��)�rrU�C]���PK3wu�����ѯkh��6��Zڴ7��q���U6�ޒ��߁Kuii
��"�T4r����m�G�W�$��<$>� '(�q"��t|zY�a�	��ؖF��C7 
)�0C�Dȗe(�	i��X��P�&>��Y��NBS�J���_�8�|P�OF�!K�ZK?����<&MA3q�%<�>:н�=7��ԇ�d��b��<t����}C�d�z<��*�(���g�Å�j=�GGY&���cg>[������'Ov�7{&?y�u&�IW�}��ж&���XPG��m�v�̠6{�Q��3(Ar�|L�9Dm,���+��>m�:�m]�i��uFn���篾��G�FPnf���}opM��&��r�@�=l��e�%�H�_�rq%���t���".zY�PH4�!;�o���+�.;�a���!�'�����i)Qu��W��}r���e�
 œ�G��C���XA�7[�%�ҾԄ8Ė�|�=|l�v�U�T*�$O�U���C�i�'�#ӎ]@��2F���E�;�w�D��C��t#;��!��1Y#�!P���ȄRu����2�ҭ�C�Q��k:C� �v�^n-:���hM�}(�zQ<�C3/ꪪ���fNmIǑ���;�*X�Q�����J��'�#�����Ù&W'Nud�N��>�-�Pd[IA�o&��Ƃ$a	�M<�EpE���9��ϰ��tS��:�^�St(��������5<`k�e>��Oc���\�����
��u�B��}���7���_�ߡ���.f�W7nݽ�yg��x��Uu���(ң�p(�d! �!)��ё��br�	Zch1dd&*Q� ������`��$�}��?�t���/�4��7��L'�O�=��!��� �[���.v�L��&����6�?�"~����6��x�����G|z���{��N8�ww���S�%�<pap��\�؍F�ۖ��ee���'��
@]/>���$l̘Lj�;��S5V�`qq��L�B�9��j���3��`zĥ�3p�`z�Q�ך��|\�w�r+���*��%(�q���!A�>���p ��w�^�߉k���'��8�����SP8>���bH��׼7w2��A*|OF�}s���f�?�����T��&���y@ͭB��'�����.�ʍJv���y:]W���X�T�a���
�6��yonf��Q����ó�O�/���X�3�',�ə�Ct�Nq�r'#X�I�Lu�A+5��'�� 4s̤���q�;�g�c���O�g�O713z{j�gŏ�T���4U��������ΐN���<��G��9R�:ƍjݪ�-ʎ��p�8���7�k)Pn��C��w����+M$M�T�0*j��홴��������j���8ѠR�{�J�2�Ysn�n�@7��$+�y�Z*X��`m�I�+��8)�� _��l��N�i�ы��f��b �f�)�6�B?�4����î��x���86�E��2��O�5�PϏ#�#����c�p��Z.�����aD�����{����0|�i'�h��L^*U�M:5�t&�Z-��Y:0���6�I���P����T
��&�>�8`���h
�H��ǀQ��'���*��P,�D:�+���aĳ��,�T�|����	�<(�A"�9iՎe:*�cL#��՚ۑ$��U�Q���	i��u��AXr3IO멡��&|,2���C>[�,A�"c�P��g�?�_�T�l����g¹8WP�����gvR�U��{s*\(4j%��N����bv3p�7�-@�糘��زǗ6=`�u�7=Qwl����(������۞��#-P�Dr��4�o7�B�R"�F�.�f�8��F6ؗZR��G9V9����t]����*�JGԇ]h3�������y�O��������S����4U:[��|B��OB���)�g����옎)0J�ca��L���x=9IkǍNL�1!+��~�c��v�T�~PNe��J�ެ��@;)���vb0���3��;���~�#~~���A܁oo���*:�u�?�@`q�{����Jx'���� j���%]U������Ć���;{N�=�fϡ���~�k7Al@^^!n/y<��� nq��w�}�������ǎ���{���{��%�ٹ�,?G@����sVt\��J�o�
�H�(,��S6_�]/��8I���	�A$����{�|I���@ď�x���E@��P�� ��!Ūf��9��FF�D8����t�b��H�U(\�8����r��lbВEs��X�&͚�vc~4H�:
7�"�ppY q?�Z��@��{���3ۉ��H�2�	�@�Y�8]ջ�;����@�U��Y�t�iQ�n}08�5�(B���Ѓ���^���@'�÷��0`��mj���.���ͱ�op��'r�Z�3f\��?����s�&���(��s{W��Q>���fgԭ�O�����u>ι�?�� ���� '��k�'Uq�(YK�����K�
�����0��Ӓ^�䰗ʻ�.+﮸����c�=������:*g.f	9υ�=�2�F�d�;�Zʗ���6*6�eM�ʅ��v����C�1O��4�W�՜T�W'e��jQ%���5l�z|R(�)s�	�Y�
�H��T�)��r��:��t�Qۣ�H�{r �t���x��;�$2�S0��*$X)s]�F�Q�$g��r.�����0��F�9���@8i��R�A��$kt4�ʹ���¥"l[�f+U�u�~.@��D�ѣ�y�W��'��se��7o��y#ř�oh�> �}�M�_�:��u�
=���eB��<��=��Ȧe(����f��%�U��+k�Ȭ͆2q��^1uU��l���K�V��L�E���>}��z��S�����S�o������Ed�#�F�=TE�cH?K��IύJ���}p7+�]E�jG�����Gez��_��H
����#Α��n��󆗝w��a%ɐMS6	���>��k�ϥW6�K����<�9���8/���s���P`���f������&�Y��/�����s����C&�v[�J�"�H2a�dR�(xم��9<L2��0	�Lr(�@��uQ7և?n麊�}��rZd��6��KwO�I7nw���o}k�|�����*̥Kx�eI܏��=ޯ�c��"�[O�<�F�V'�s�}�k��������߯����UM���̇7�k�HP;��	��&�?zXPI���"�AS���yoȸ���ƙV4�dwCE�b��t������6A#��H�0����Y�;'$�Y���G�Dj2�Y�Q(�ˡ�`�Fv�F��p���E����a�/Ξ;��kD�>��?��C� 8}��t��>z(6��ܕ��ޱ��C,kc��5��+�����Q�Hu!�FL��/�OX�z.鑀��$�פb���X5��C��:Ms.֛^%Ks�#f��'��Qs�g:�(:��D`]ƙ��b�{J ��%C�De(��dE��OU�bP;�r8�~��@�cpN�_ ���]�h]��q&M���v��a��Z��Ʀb�%w�A��%|���M� ف�!��>�����tbSq�4Z]s"Z�\��p'ލ��nn�ϰx	�<������� �_18%ER"����8�D�+׀ε5N�9����~�'����]L70��Úֹ�e�*�l]8\WcmlO�S��w��L��;��eE��HJ�����g�z����B�[8�w�/���v�Ta׀��u{K�$�<�=	.�x�t�1l~����J&#>��'Zr[w���	�*����B�ɠ�Lm� ?K�]5W���e��a��S�~s�G�X�(�����ف0U���
 ١l`SP���{�܄�C�B�kc[��Gж�j�3v��Wn��z[(B��'v��_"]/���fI��.T�S�٩8%�������Ŗ���/�?�u�I�-!4��wk�Q��;5�Ht8Q����-Yb�.�����a� y�����}_�qC�#� � i��8ٲ�[ �'�.��#T(�R�(��J�lLӭe�ĭkEMS��n ���c�Xp�)�����eQG�m��&����,(-�D
��b��n�+�Ϡ��D7���X��_�r\1>;v=�@���1�"����U�������y����W��q��a>y�/t��gn����q0c��� ���"�^��S[Wb0��� BG�|��}k�%��G�"�:��%����weM�jK��_q�{����Ӊ�ˤR*8�T0����h�5H�]@w�z���P��Y;3w�ʻ���FK1[��fǏH���:^Tz�_��z�|=�v'lu4����?=����[#�?beϳp�k���w%|�_�������}$��Cێ�`�����O���۶�0��p>i;F�M���>������m8�{Pٱ�����"��?�Y�w{4b�������
�����֫��;���s��3C�d$'�?��W��K�����)+�q�C1��m�Z�(-����M��a��PA�MŲ~b'�{���_K�t�Q��?O��W-���꺓��v��_�$Tt���?Č^;:VsL�vw�O���#�E���zq��/�h0��Mh�r�`�l�Ӝ����E�!၏���3�0��S�z�^nף�>� =��F�c|����Ϟ5H��/D���϶�xvޟ�'{I5J�zO&���RYP�*�y~6dEl���oC�UU��s3��EQ4.BF��
]mfwvǏ��<���w��/�V{yꞹ������&W%���r�j���J�]55�xu?/���Ê��'}���u��҃0�¿��AP���V#k>���� 
��S��}���KզT�Żk����]څ�<G�����ɯu5~�?ww�TP��o_��e�� ���'����_����s����V�S�M�l��d�?xޓ�G2���t�t�_�3/���5K�C���ݔ�I�2;�W��^�����$�|<�'c-��mӬO�T�?~:��x�m��!m���{��{�?/���i���C��x����0�i�����:��'I�S�����|T��E<>���X?��i��\�p����_������_��뗎{��(Rx�דе?�?�uHc�?��t������'p�)��,��R�����A���i����G��
���4 
4�@
4�U�&�G�]ȅ�w���`�����?������1볜�Ƀ�1�铴�{�˳���q}�%i�tX����q������F�����?��M쿻~��hJ�b���B�/�E�%,�c۰^�~�3�������n�K��j��hY�q5@7U���ڮ�U�)�� �_Dut��M�	�l_)w���I�De=�!���im�9�ݾm�k�>tw�X�V�Mw�
Z�j0)K-��m�Τ�������Ee}�s�<����)��9�%�$"���P��SA������H��������;��������������8=�{����9�?����������8�D���?s���k���O9�����!K45���/�Rs�����h�	�:�U����)����⿐��
�`��68�Y���m���������'��������Ư�?I��4��_�����S�q��k֓���������L�?]]�_�?q�'����5D/����K?���~FQ�ܙUF����>/e�ȸN�LW���8,��f/N��r�V�P��먱�.B?���ڔ�p⯅b���6˅��Ţ���e��Kf�9H���>/e��{�>K�z�dC%(ke���r��n�h0��m]�����l�,�Գu��~5B'��Z��J����M�CaXi2�B����s��A�lI-u&n�f�m�j�M�4���a��z��ԅ�P�z_�Z���mA�\�����`��
D!�	�����_.���3C��T�RF.���'��?���?���?e���`��`���<��0���� �����r��4s�����'���!�?��g�W��G�߹��;����k���V�kLs����������?��wn}�k�����[����_�����tb�:��7��,�u}iNU!l��5�
yè�MY�QUT����͖�6ӧ�]q�,0�*�L�0t%<���c��t!:��ʹ&@�!��.�H��:m�#�}��n�[�4��@Ш!Q>�F�\c;�3�̗���;�]v%�h�%+a�0���D�=�R���#&��VA��i詼��������F����c�����?�4��o����|���>�����_��$�a�?������n��=cp��h��h��y��|���u9�%�fX� #]ƥI�t0��F�?I���t�;���C���vCq^C��� �<䶫�[L�@n��w��S������Y�-e��2ش��hͽ���Ң�t��j����[w6Lg��+V�@�r�R�j{�94���z33w��A���������!��=�]�,����������̐�?������n|?���������u��є�v���B6=���i�++ŝ�z��K[~8�\�?�B2U�%5t���>dn��qS��:@��5t%iף�q��AH۹�lY��$��M�a���n�]WL�Іӣ��{+�����yX�]����o��<�A�Wv��/����/�������� ������S�����K�������{��Z@�K�`��i���d\*����7�D�� x�������5�L ���'z  ��� GS�-�&�HH�T��	��= ���?�̦&���zNj���c�ު��
ET�n"�R��,K6K��%
�a�*�����ƍ��+i��V_�xc=����!A��`ߵ��K�u�N�+�= �͢���X��R��'"���0�J�B��o��-Qv8��^���a�*��*iUC�jj�.�
�z}���8'��%5!!b�|�u�WЕ��*-�V�E����ݮV��n_V+3d�����GՊ0G>��ּ��K$#L�ӹ^�����`'8�ޏ7ڲ/�� �N%����
RX�]2<r�4����?,!�� �#��	,a���SA:��~yEZ��^��?R����?������O��g�t�?������(c=��	�r1��m�a(�g1��|�v�x;�&	��x�b}�fl
;�
y����	�4�;�{Ug3>��&ݝz���j	�N6"j`,[ԁ1tj^����_˔��"Pj{�:P#}>SK=l�,s�Bd"�))V�i��T1Bԫ����`B���=�Ϙ���l|���x�Wl��9-B��[������@�o*H��c���/������	��i ��\��!�/%����7��{���5��U�����>������| -���;�O������t��ml���Q�{�X��;�p��'���o��I��,ؗ�o�0�gr��א��~�[�ȋ��QԮ�͵ݦ��j�����]�p�N����j�ye��aWk��5#��ٸ˳ʸ�b'f�ߵ5A+ڞ5�:�c{�H��UCݫ�L�R�� �F��X����{��Y�=�r �!�[��z��U�GVfei��bj��jW�+L*2����˔mo���AW��Z��P�3��K���)�>�t�G�^��Uڷf�f�ⷒ�j`�3�7{o^�+[Q#�g7�i�嚍�ų[�h�B�ӲSC쿣��!%������o�/�O��FH��!<gȃ����Mb�������o����o�������$�@��������������ӯ�	r��'��B�O* �_���_��Ͷ�+���/���o��S��P@"�����$��� �O`	��)��4��'��ò�1����������������������p��A�?��A"; ��g��tB���H9��Hi��{�(�H�� ����G�p|
������/���<�P������_.����� �O	y�(Iy����(�H�� ��� ����_V��Cd����������̐3�q����?A����T ��� ����������� �_8 �?#������\�?�\�?��������6���C�v�������?څ�ra��	��_ȃ�7���z����O��o�/�O	�����
r��8~��g���,Gb\����K9��S�8�p���$��6α6��m�6E��m�US��E��dp��3���f����t/��|�8��<P��Ev��S�JE��C���U�f��(�'���(�����3b30Cs���z�0zs|(�[8���4�?@�ָ�����.N|��*�a ڳ�|�iT	��]���}E.70��`�K����Ee}�s�<������^�����yX���������y���������C�����;���K�����6�ba�-�u���������E��[2�����?^[kbP�Zh��@����\�wbl��;|WT�h����Y:��]IX֖�\����#��ԍ���j�6��{+��_���oJ�����?���xs� �!�꿲�A��A�����8�6`ȅ���������Փ�_��'��[�ԖV�����і���/������ζ]l��bO���3N���h���Js5^4\� o�����rw�X�Ov���Z=״�-^�m3C���f����p8��e�c?�̂:Pf�a�^�Gȵm���t��w:)���7�b��ǹ��(��0t��b�*ae4j�QڶD����zu㋇i�rbt��U�������+uI-�;���e}�'p��q�!�kݶ�鮲���͆/�*�&E��x$>�+�\Ž`<Y<^ ���ܡ�fI���lA���Ͽ�V��?_y��������űX���_2�O|��I��Oy��� ��3?�'E7H��+���?KR��i �O��+���T���u=A�#wH��_��`��,E@�/��3�$x�{���N�Yg�nt�+��&���ȑ��GQ����D<�,�G�s�M>~�e�t�|��^�N!?�}?.!?�>�W���n�7Z?]ں\B�f��#��j	�P���b��EZU�>ꪋb'�Y73��l���(��Ī)H��&��¯�6^(R(�����-5 �C�����[]��u7�I��]���h����隚[N�lNM�*6\q�[�2�l
���v��~A��I4���9@�|OU�������.���k����>����و�]�h�+��}S���\7��	kͅ�3�3���:o<J)M�Ý��%o)˱Ը=mkUV���D5�A�'�%��BTWv��Z�x�9���lu��
��bv��,j�2�h�J,'Sf1bf�����=w1�@7ê%Y�3�U6��N���Ò�X9!�q�8Z,�i}��ݞ�����(��#n����oN�I�Q�h$ZS5ʤQS�fMG�t1N�u�S�4M��kuS�Q�:bhuT5]���WB��;�����?2��'-�i.��w4WC a����UW;C>hd���%f/X�1��V�<U+�K�J�V@��s���J�/�����2�?��o����<���+/���o����߹�7������ڧ���~��I1��"����cW�3ri�7�?u���OO�uBB�}��z��o�1��3����=��7���w��]�~���~J͉�M�=��&�#9R��A�h��N��龵�{h��!�6oV�/�����i�b8���4���H�<��~�K�~W�t��j��sX�fl�UnR��X7[F�G~�n�)#��'����1��8��3QCG���&(22f���R�BV"o=Nt���� ��Da��w��b﷧�J�a]�C8<J�����~W�A�a��?��SN�c�'TR�u��i��4�eS~:�~"(�05�PQ�V���
�%����D���5��{=�������/'�H�_�Iz����6�t�s�mU� 
>���HNo:����˖L�@/�-���\�a�O����xu��
<}� _E�����?rA)��������_������e���E�?��W���K0\���ߜ�En��0
��������������2�aI{Jg�nt�Y;{p[�%���_�V��i���qb&׾��׵�ET���,>�GB��Ϗݕp���c�ݤˤ�2��d��יk�S�יk�ܺv���#�km���y%���u^Nr��ZƑ3m�㽥��v���hם,x���F�W�SG���X�8��F�Hޢ���U�>���ZË.C��n�#DwJ�L�I.�_�K�W��0I�2�b9%�6�5�bc)}\����r�]���ۖ�I݂0v��&'ʝ�R}�t�E����k�3�o���!7���x���[3��S����<#�a,~��bS4�\ӑ�1u���°n�kAl�)Ć�O?s��?�2����!�����/)�����_��+��?/Ja���S��k> �� ����o0��߫�s�(#�����_�������,Ja�ߩ�X��� ��A�GP�� ��U��K���O�+�������H`��R�?u�����	9��M�?��������;�@����ԅ( ��/���f�7����
�P�p ��_8��w�?a���@Y�ԅ(y��������< �?������E)�r���?rA��$�`��m�W
��ݩ� �?rA)�d��R����?Ԁ��@�P�� ���?���?P�p ��m�R�?��/e�P�����W����P�� �@��b��;�@��\P�����`��m�W
���� �_��$���B)��_@�?����o���
B��om�x��/������_Co�P�7'���uCQ�hjI�z�(r��u��uS]�5�0�6P'u���j�����P5!��k=�?;���5����������H��,��������%0�#�ǭ8�����"�=~N�&+"����"ɓg�'����q�͡��%U��0���ö���^��L6]=��f��aGy>�bUv;�#xa���N�P�3�2��ar����%��T�[!&Q�~m�ۀ�h�<J�ި�F�@v>�{7'U�/�0����š��?v��o	P���š���C���Ň�,�2�Y�����W~��ǪVw�A��3��UM�N��e��G���jg͇W��%Lֽe�7Z{�nȶ�y�l�(��Rވ&{�F7���m�tx�2�KYe�����v%O}u���Ђ�\�����E)��߂P����z�3^տJ��
���_ ����E��,��y��H����w����_���u�8l��Qfu�;���N�5�?\�}:D�m��5��d_:۠��6���LA��pwvs����d���Y��Y�0���dZ�Rb.�Su�SI�f^���l�q�ePSu��Q��	���xv�a��:���g��mxfy�rñp�MV�ZB�Ut�����YV7���3g-8�$HI*�B��� �c=S�=�|��'����8�2�S�ن>�*�����:��zh���L�>��Ü����EIȤ�E)ΰC�q�7�5qw ɤ����kTf���5�S�A����T^}�� {�y�����!w�?P��J���m�� �����㇧5���P8 ��/��1�F�	�?��YX�W�m�?��������?��x���������O������R�?��;���?Z�� ��A�Ƿ�R�?������� Y$�����_)��(��������'o�1P�#|7������?����F�����+P��4���u�o���4�����8�~d���r��܏�Ǡ?����~@����u��5��w����7����*5'6��6�Ԏ�H��}��R�:�ǧ�ֲ�ݞ�HڼYu<��pZ�N2��z�I|X�LD����kȖ#�$K��^��{M�������p���-��b��T)*V�͖��Ñ�7�{�H���iA��~gf�����#{�y3
_�z��B���[�j�{�h=7@"�7Q�f}��]��������qX�:��e�ߎà������ߓ&�E_�7`��m�W
�����T��� y�����_��c> ��@�/P���*��'��OA(^�}j^��x� �������_���w� �WF)��_�g��|�������nZM;fF�/��k�:��O5�߰~������=�����ս��� ��?s �}�m�����-�[�ī:LRY^�ް#��.�4�64"����F��6�v�6�aLo�52�m����KH{B~= ʒ �L �%|+`�0ɀ��i˭�u!`Tb�|�ZچH�2��R��ڍ����{��)��Q��ñ܌�!��*�W:l'fh$Y���t��z3��(��Co������P������K�&��������5���#�?��?^�)]�Q�I��Z�UcYC4�$��5��LC�A����b��nhi�i
[�����e��{�?A�>���?GԂ:�Ok��"�N�DDN#�����`���l��<�W��?���f����UՃP���'8�Ykׅ�5!%v`�T���/e�D;Xuu���9��i9md&�fȐ�|�#+%�����E�P��8;�gM���oe���WJ�� ��0���M S3��k�Q��_q���_0ݹS{������K��5�NWl�v�q��)s8`'V�W��rGb;m� x�����s	�nM	(��CaB̐ڄҚ�^��iWk��l�=Q�q�Bp��D��K�Ȝ|��sQ���&���0����]��C)�@�Wa �_ ����/����P�Ѐ���� j@����i��,��k�z@N�}߄�*����-�߄t����c���/���� �� T�V�S]�����T9�
���D���ݩ���Ƥ�ES�T��pM_-h*>��p�l�֓���y"�vK"Yk������Xwű���2�t�2ISy�y��\�V2gYe�d��'��2n�I��2_ ��0`��?l�[M�~<�dZ�8> =sS��C�g��/_�\zi�>4��Lvu��\Hϥ��u�Oz��p ��1�	ku3��F7u���'��W�����k-�]sdn����m�}���zܶ�=:��	&�Z�����x��ڼ�����{��m�ˇ��1�;���(�9�c8���p�-ï��P����Ǳ�ׇ�����ꥌz6a\i0�@�>p�C�5��?��v�!��� ܘ�kT���wQ
b�3�U�ovq��Yw��+���e������9[�}ý�����Ow�_�l��Y�+�ՏK����2���g�I�8�z��?�ߙ�CI���H0����_�����F6��"����+�Fq��M��J:~\Q]7{c<�_FPdĕ��>�oĆ��N_#'���p�_���U/��?ٞ�P�*�mT�]���N�n�	�/~}��?*������8��/��̰�a�8�����]��U���J�,�O�^��W~Kw����o;t��_��+˔E2����7o��?��������fT�/��O�������<F�K�+���o*�+���u5��Ƽ\����)�;�w|���~���8Q�3*��p�FFRG�G���U�������@�no*��vo�ߡ�5��kӣ���&>R���c0�J`!�	-���^|ݾ�_v�~S����HJ�_sv�a#�a��Ń�#�=��V�8��)��ON�ᳳx�>x\o |���Cg��z݆$������vQF��օ_�R���g]�Uv��/O�q̞�����7"�Q0
F�(�`P  �h�  